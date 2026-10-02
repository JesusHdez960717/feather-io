import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:service/feather.dart';

/// Subidas multipart de S3: se inicia, se suben las partes (cada una a disco
/// como stream) y al completarla se juntan en el objeto final.
///
/// Las subidas en curso viven en `STORAGE_VOLUME_PATH/.multipart/<uploadId>/`
/// (un nombre de bucket no puede empezar por punto, asi que no se lista):
/// `upload.json` con el bucket y la key, y por cada parte `<n>.part` y su md5
/// en `<n>.etag`.
class MultipartService {
  static const String folderName = '.multipart';

  /// Tamaño minimo de cada parte salvo la ultima, como en S3 (5 MiB)
  static const int minPartSize = 5 * 1024 * 1024;
  static const int maxPartNumber = 10000;

  static const String _infoFile = 'upload.json';
  static final RegExp _uploadIdPattern = RegExp(r'^[0-9a-f]{32}$');

  final Random _random = Random.secure();
  final ObjectMetaService _objectMeta = ObjectMetaService();

  Directory get _root => Directory(p.join(env.storageVolumePath, folderName));

  /// CreateMultipartUpload. Las [headers] del objeto (`Content-Type`,
  /// `x-amz-meta-*`…) se guardan con la subida y se aplican al completarla
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
    await File(p.join(dir.path, _infoFile)).writeAsString(
      jsonEncode({
        'bucket': bucketName,
        'key': key,
        'initiated': DateTime.now().toUtc().toIso8601String(),
        'headers': headers,
      }),
    );
    return MultipartUploadModel(
      bucket: bucketName,
      key: key,
      uploadId: uploadId,
    );
  }

  /// UploadPart: guarda la parte [partNumber] (si ya existia, la sustituye) y
  /// devuelve su ETag (el md5 en hexadecimal)
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
        message: 'El número de parte debe estar entre 1 y $maxPartNumber.',
        resource: key,
      );
    }
    final dir = await _uploadDir(bucketName, key, uploadId);
    final part = File(p.join(dir.path, '$partNumber.part'));
    final temp = File('${part.path}.tmp');

    final hasher = Md5Tap();
    try {
      await hasher.bind(binary).pipe(temp.openWrite());
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }

    final etag = hasher.close();
    await temp.rename(part.path);
    await File(p.join(dir.path, '$partNumber.etag')).writeAsString(etag);
    return etag;
  }

  /// CompleteMultipartUpload: junta [parts] (en orden) en el objeto final,
  /// que sustituye al que hubiera, y borra la subida
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
        message: 'Hay que indicar al menos una parte.',
        resource: key,
      );
    }

    for (var i = 1; i < parts.length; i++) {
      if (parts[i].partNumber <= parts[i - 1].partNumber) {
        throw S3Exception(
          S3ErrorCode.invalidPartOrder,
          message: 'Las partes deben ir en orden ascendente.',
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
          message: 'La parte $number no se ha subido.',
          resource: key,
        );
      }
      final stored = (await etagFile.readAsString()).trim();
      final given = parts[i].etag.replaceAll('"', '').trim().toLowerCase();
      if (given.isNotEmpty && given != stored) {
        throw S3Exception(
          S3ErrorCode.invalidPart,
          message: 'El ETag de la parte $number no coincide.',
          resource: key,
        );
      }
      final length = await file.length();
      if (i < parts.length - 1 && length < minPartSize) {
        throw S3Exception(
          S3ErrorCode.entityTooSmall,
          message:
              'La parte $number ocupa $length bytes; todas salvo la última '
              'deben tener al menos $minPartSize.',
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
            'El objeto ocupa $size bytes y el máximo es ${env.maxObjectSize}.',
        resource: key,
      );
    }

    //se junta dentro de la subida y se mueve: el objeto no se ve a medias
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
    await target.parent.create(recursive: true);
    await joined.rename(target.path);
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

  /// AbortMultipartUpload: borra la subida y sus partes
  Future<void> abort({
    required String bucketName,
    required String key,
    required String uploadId,
  }) async {
    final dir = await _uploadDir(bucketName, key, uploadId);
    await dir.delete(recursive: true);
  }

  /// Borra las subidas en curso de [bucketName] (al borrar el bucket)
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
    //una carpeta no se sube por partes
    if (!S3Validator.isValidKey(key) || key.endsWith('/')) {
      throw S3Exception.invalidKey(key);
    }
  }

  /// La carpeta de la subida, si existe y es de [bucketName]/[key]
  Future<Directory> _uploadDir(
    String bucketName,
    String key,
    String uploadId,
  ) async {
    _validate(bucketName, key);
    //el id forma parte de la ruta: solo hexadecimal, sin `..` ni barras
    final noSuchUpload = S3Exception(
      S3ErrorCode.noSuchUpload,
      message: 'La subida "$uploadId" no existe o ya terminó.',
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
