import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:service/feather.dart';

/// S3 multipart uploads: one is started, its parts are uploaded (each one to
/// disk as a stream) and on completion they are joined into the final object.
///
/// Pending uploads live in `STORAGE_VOLUME_PATH/.multipart/<uploadId>/` (a
/// bucket name can't start with a dot, so it isn't listed): `upload.json` with
/// the bucket and the key, and for each part `<n>.part` and its md5 in
/// `<n>.etag`.
class MultipartService {
  static const String folderName = '.multipart';

  /// Minimum size of every part but the last one, as in S3 (5 MiB).
  static const int minPartSize = 5 * 1024 * 1024;
  static const int maxPartNumber = 10000;

  static const String _infoFile = 'upload.json';
  static final RegExp _uploadIdPattern = RegExp(r'^[0-9a-f]{32}$');

  final Random _random = Random.secure();
  final ObjectMetaService _objectMeta = ObjectMetaService();

  Directory get _root => Directory(p.join(env.storageVolumePath, folderName));

  /// CreateMultipartUpload. The object's [headers] (`Content-Type`,
  /// `x-amz-meta-*`…) are stored with the upload and applied on completion.
  Future<MultipartUploadModel> create({
    required String bucketName,
    required String key,
    Map<String, String> headers = const {},
  }) async {
    _validate(bucketName, key);
    if (!await Directory(p.join(env.storageVolumePath, bucketName)).exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }

    final uploadId = List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final dir = Directory(p.join(_root.path, uploadId));
    await dir.create(recursive: true);
    final initiated = DateTime.now().toUtc();
    await File(p.join(dir.path, _infoFile)).writeAsString(
      jsonEncode({
        'bucket': bucketName,
        'key': key,
        'initiated': initiated.toIso8601String(),
        'headers': headers,
      }),
    );
    return MultipartUploadModel(
      bucket: bucketName,
      key: key,
      uploadId: uploadId,
      initiated: initiated,
    );
  }

  /// UploadPart: stores part [partNumber] (replacing it if it already existed)
  /// and returns its ETag (the hex md5).
  Future<String> uploadPart({
    required String bucketName,
    required String key,
    required String uploadId,
    required int partNumber,
    required Stream<List<int>> binary,
  }) async {
    if (partNumber < 1 || partNumber > maxPartNumber) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: 'The part number must be between 1 and $maxPartNumber.',
        resource: key,
      );
    }
    final dir = await _uploadDir(bucketName, key, uploadId);
    final part = File(p.join(dir.path, '$partNumber.part'));
    final temp = File('${part.path}.tmp');

    final etag = await Md5Tap.write(binary, temp);
    await temp.rename(part.path);
    await File(p.join(dir.path, '$partNumber.etag')).writeAsString(etag);
    return etag;
  }

  /// CompleteMultipartUpload: joins [parts] (in order) into the final object,
  /// which replaces any existing one, and deletes the upload.
  Future<CompletedMultipartModel> complete({
    required String bucketName,
    required String key,
    required String uploadId,
    required List<CompletedPart> parts,
  }) async {
    final dir = await _uploadDir(bucketName, key, uploadId);
    final info = await _readInfo(dir);
    if (parts.isEmpty) {
      throw S3Exception(
        S3ErrorCode.malformedXML,
        message: 'At least one part must be specified.',
        resource: key,
      );
    }

    for (var i = 1; i < parts.length; i++) {
      if (parts[i].partNumber <= parts[i - 1].partNumber) {
        throw S3Exception(
          S3ErrorCode.invalidPartOrder,
          message: 'The parts must be in ascending order.',
          resource: key,
        );
      }
    }

    final files = <File>[];
    final digests = <int>[];
    var size = 0;
    for (var i = 0; i < parts.length; i++) {
      final number = parts[i].partNumber;
      final file = File(p.join(dir.path, '$number.part'));
      final etagFile = File(p.join(dir.path, '$number.etag'));
      if (!await file.exists() || !await etagFile.exists()) {
        throw S3Exception(
          S3ErrorCode.invalidPart,
          message: 'Part $number has not been uploaded.',
          resource: key,
        );
      }
      final stored = (await etagFile.readAsString()).trim();
      final given = parts[i].etag.replaceAll('"', '').trim().toLowerCase();
      if (given.isNotEmpty && given != stored) {
        throw S3Exception(
          S3ErrorCode.invalidPart,
          message: 'The ETag of part $number does not match.',
          resource: key,
        );
      }
      final length = await file.length();
      if (i < parts.length - 1 && length < minPartSize) {
        throw S3Exception(
          S3ErrorCode.entityTooSmall,
          message:
              'Part $number is $length bytes; every part but the last one '
              'must be at least $minPartSize.',
          resource: key,
        );
      }
      size += length;
      files.add(file);
      digests.addAll(_hexToBytes(stored));
    }
    if (size > env.maxObjectSize) {
      throw S3Exception(
        S3ErrorCode.entityTooLarge,
        message:
            'The object is $size bytes and the maximum is ${env.maxObjectSize}.',
        resource: key,
      );
    }

    // Joined inside the upload folder and then moved: the object is never seen half-written
    final joined = File(p.join(dir.path, 'object.tmp'));
    final sink = joined.openWrite();
    try {
      for (final file in files) {
        await sink.addStream(file.openRead());
      }
    } finally {
      await sink.close();
    }
    final target = File(p.join(env.storageVolumePath, bucketName, key));
    // If it can't be replaced (an open object on Windows), the upload is still
    // there and the Complete can be retried
    await FileManagementService.replaceFile(joined, target, key: key);
    await dir.delete(recursive: true);

    final etag = '${md5.convert(digests)}-${parts.length}';
    await _objectMeta.save(
      bucketName: bucketName,
      key: key,
      file: target,
      etag: etag,
      headers: {
        for (final MapEntry(:key, :value)
            in ((info?['headers'] as Map?) ?? const {}).entries)
          '$key': '$value',
      },
    );

    return CompletedMultipartModel(
      bucket: bucketName,
      key: key,
      etag: etag,
      size: size,
    );
  }

  /// ListParts: the parts already uploaded to the upload, in order.
  Future<List<UploadedPartModel>> listParts({
    required String bucketName,
    required String key,
    required String uploadId,
  }) async {
    final dir = await _uploadDir(bucketName, key, uploadId);
    final parts = <UploadedPartModel>[];
    await for (final entity in dir.list()) {
      final name = p.basename(entity.path);
      if (entity is! File || !name.endsWith('.part')) continue;
      final number = int.tryParse(name.substring(0, name.length - 5));
      final etagFile = File(p.join(dir.path, '$number.etag'));
      if (number == null || !await etagFile.exists()) continue;
      final stat = await entity.stat();
      parts.add(
        UploadedPartModel(
          partNumber: number,
          etag: (await etagFile.readAsString()).trim(),
          size: stat.size,
          lastModified: stat.modified,
        ),
      );
    }
    parts.sort((a, b) => a.partNumber.compareTo(b.partNumber));
    return parts;
  }

  /// AbortMultipartUpload: deletes the upload and its parts.
  Future<void> abort({
    required String bucketName,
    required String key,
    required String uploadId,
  }) async {
    final dir = await _uploadDir(bucketName, key, uploadId);
    await dir.delete(recursive: true);
  }

  /// ListMultipartUploads: the pending uploads of [bucketName] whose key starts
  /// with [prefix], sorted by key and by start date.
  Future<List<MultipartUploadModel>> list({
    required String bucketName,
    String? prefix,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    if (!await Directory(p.join(env.storageVolumePath, bucketName)).exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }
    final uploads = <MultipartUploadModel>[];
    if (!await _root.exists()) return uploads;
    await for (final entity in _root.list()) {
      if (entity is! Directory) continue;
      final info = await _readInfo(entity);
      final key = info?['key'];
      if (info?['bucket'] != bucketName || key is! String) continue;
      if (prefix != null && !key.startsWith(prefix)) continue;
      uploads.add(
        MultipartUploadModel(
          bucket: bucketName,
          key: key,
          uploadId: p.basename(entity.path),
          initiated:
              DateTime.tryParse('${info?['initiated']}') ??
              (await entity.stat()).changed.toUtc(),
        ),
      );
    }
    uploads.sort(
      (a, b) => a.key != b.key
          ? a.key.compareTo(b.key)
          : a.initiated.compareTo(b.initiated),
    );
    return uploads;
  }

  /// Deletes the pending uploads of [bucketName] (when the bucket is deleted).
  Future<void> abortAll(String bucketName) async {
    if (!await _root.exists()) return;
    await for (final entity in _root.list()) {
      if (entity is! Directory) continue;
      final info = await _readInfo(entity);
      if (info?['bucket'] == bucketName) await entity.delete(recursive: true);
    }
  }

  void _validate(String bucketName, String key) {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    // A folder is never uploaded in parts
    if (!S3Validator.isValidKey(key) || key.endsWith('/')) {
      throw S3Exception.invalidKey(key);
    }
  }

  /// The upload folder, if it exists and belongs to [bucketName]/[key].
  Future<Directory> _uploadDir(
    String bucketName,
    String key,
    String uploadId,
  ) async {
    _validate(bucketName, key);
    // The id is part of the path: hex only, no `..` nor slashes
    final noSuchUpload = S3Exception(
      S3ErrorCode.noSuchUpload,
      message: 'The upload "$uploadId" does not exist or has already finished.',
      resource: key,
    );
    if (!_uploadIdPattern.hasMatch(uploadId)) throw noSuchUpload;
    final dir = Directory(p.join(_root.path, uploadId));
    final info = await _readInfo(dir);
    if (info == null || info['bucket'] != bucketName || info['key'] != key) {
      throw noSuchUpload;
    }
    return dir;
  }

  Future<Map<String, dynamic>?> _readInfo(Directory dir) async {
    final file = File(p.join(dir.path, _infoFile));
    if (!await file.exists()) return null;
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  List<int> _hexToBytes(String hex) => [
    for (var i = 0; i + 1 < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}
