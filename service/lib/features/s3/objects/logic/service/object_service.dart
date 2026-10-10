import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:service/feather.dart';

/// The objects of the buckets, on disk: upload, copy, read, list, delete
/// (one, many or a folder) and download several in a zip.
class ObjectService {
  final ObjectMetaService objectMeta;

  ObjectService({ObjectMetaService? objectMeta})
    : objectMeta = objectMeta ?? ObjectMetaService();

  /// Deletes every object and folder of [bucketName] (its folder stays) and
  /// their metadata. The bucket must exist.
  Future<void> deleteAll(String bucketName) async {
    await for (final entity in Directory(_getBucketPath(bucketName)).list()) {
      await _delete(entity);
    }
    await objectMeta.forgetBucket(bucketName);
  }

  /// Stores the object with its [headers] (`Content-Type`, `x-amz-meta-*`…) and
  /// returns its ETag (the md5 of the content).
  Future<String> uploadFile({
    required String bucketName,
    required String key,
    required Stream<List<int>> binary,
    Map<String, String> headers = const {},
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    if (!S3Validator.isValidKey(key)) {
      throw S3Exception.invalidKey(key);
    }

    // As in S3, the bucket must exist; the subfolders are created on the fly
    if (!await Directory(_getBucketPath(bucketName)).exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }

    // A key ending in '/' is a folder, as in the S3 console: it is created
    // empty with its marker and the (empty) body is discarded
    if (key.endsWith('/')) {
      await binary.drain<void>();
      final folder = Directory(p.join(_getBucketPath(bucketName), key));
      await folder.create(recursive: true);
      await File(p.join(folder.path, S3Validator.folderMarker)).create();
      return ObjectMetaService.emptyEtag;
    }

    // Counts the bytes as they arrive, to enforce the limit while streaming.
    // BodySizeFilter already rejects a larger Content-Length and Winter cuts
    // any body above it; this also covers a body whose size isn't declared
    final max = env.maxObjectSize;
    int bytesRead = 0;
    final monitoredStream = binary.map((chunk) {
      bytesRead += chunk.length;
      if (bytesRead > max) {
        throw S3Exception(
          S3ErrorCode.entityTooLarge,
          message: intl.errors.s3.objectOverMaximum(max: max),
          resource: key,
        );
      }
      return chunk;
    });

    // Written aside and moved at the end: if the upload fails, the existing
    // object stays intact, and it is never seen half-written
    final temp = await _tempFile();
    final etag = await Md5Tap.write(monitoredStream, temp);
    final file = _getFile(bucketName, key);
    await replaceFile(temp, file, key: key);

    await objectMeta.save(
      bucketName: bucketName,
      key: key,
      file: file,
      etag: etag,
      headers: headers,
    );
    return etag;
  }

  /// Folder of the files being written. It starts with a dot, so it isn't a
  /// valid bucket and isn't listed.
  static const String tempFolderName = '.tmp';

  final Random _random = Random.secure();

  /// How long replacing an open object is retried (on Windows).
  static const Duration replaceTimeout = Duration(seconds: 5);

  /// Moves [source] (written aside) to [target], replacing any existing object,
  /// and creates its folders. On Windows an open file can't be replaced (a
  /// download of the previous version that hasn't finished): it is retried for
  /// [replaceTimeout] and, if it is still open, [source] is deleted and the
  /// answer is `ServiceUnavailable` (503), which S3 clients retry.
  static Future<void> replaceFile(
    File source,
    File target, {
    required String key,
  }) async {
    await target.parent.create(recursive: true);
    final deadline = DateTime.now().add(replaceTimeout);
    for (var attempt = 1; ; attempt++) {
      try {
        await source.rename(target.path);
        return;
      } on PathAccessException {
        if (Platform.isWindows && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(
            Duration(milliseconds: min(50 * attempt, 500)),
          );
          continue;
        }
        if (await source.exists()) await source.delete();
        logger.warning(
          'An object stayed open for ${replaceTimeout.inSeconds} s and was not replaced',
          fields: {'key': key},
        );
        throw S3Exception(
          S3ErrorCode.serviceUnavailable,
          message: intl.errors.s3.objectInUse,
          resource: key,
        );
      }
    }
  }

  Future<File> _tempFile() async {
    final dir = Directory(p.join(env.storageVolumePath, tempFolderName));
    await dir.create(recursive: true);
    final id = List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return File(p.join(dir.path, '$id.tmp'));
  }

  /// Maximum keys per page in [listFiles], as in S3.
  static const int maxKeysLimit = 1000;

  /// Lists the objects of the bucket sorted by key. With [delimiter] it groups
  /// what is below into common prefixes. It pages like ListObjects: at most
  /// [maxKeys] keys (objects + prefixes) and, if there are more, a token (and
  /// the last key, for V1's `marker`) to request the next page.
  Future<ListObjectsResponse> listFiles({
    required String bucketName,
    String? prefix,
    String? delimiter,
    int maxKeys = maxKeysLimit,
    String? continuationToken,
    String? startAfter,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    if (maxKeys < 0) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: intl.errors.s3.maxKeysNegative,
        resource: bucketName,
      );
    }
    // The token takes precedence over start-after/marker, as in ListObjectsV2
    final after = continuationToken == null
        ? startAfter
        : _decodeContinuationToken(continuationToken);

    final bucketPath = _getBucketPath(bucketName);
    final dir = Directory(bucketPath);

    if (!await dir.exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }

    // Lists the directory recursively, to include the subfolders
    final List<FileSystemEntity> entities = await dir
        .list(recursive: true)
        .toList();

    final Map<String, (File, FileStat)> files = {};
    final Set<String> commonPrefixes = {};

    final normalizedPrefix = prefix ?? '';

    for (var entity in entities) {
      if (entity is! File) continue;

      // The path relative to the bucket is the key (e.g. files/test/123.jpg)
      final relative = p
          .relative(entity.path, from: bucketPath)
          .replaceAll('\\', '/');

      // The marker of an explicitly created folder is listed as the key "folder/"
      final isFolder = p.posix.basename(relative) == S3Validator.folderMarker;
      final folder = p.posix.dirname(relative);
      if (isFolder && folder == '.') continue;
      final key = isFolder ? '$folder/' : relative;

      // Prefix filter
      if (!key.startsWith(normalizedPrefix)) continue;

      if (delimiter != null && delimiter.isNotEmpty) {
        // With a delimiter, looks for one after the prefix
        final remainingKey = key.substring(normalizedPrefix.length);
        final delimiterIndex = remainingKey.indexOf(delimiter);

        if (delimiterIndex != -1) {
          // It is a "folder" (common prefix)
          final commonPrefix =
              normalizedPrefix + remainingKey.substring(0, delimiterIndex + 1);
          commonPrefixes.add(commonPrefix);
          continue;
        }
      }

      files[key] = (entity, await entity.stat());
    }

    // Objects and prefixes go together and sorted, as in S3, and pages follow
    // that order: a page starts after the last key of the previous one
    final keys = {...files.keys, ...commonPrefixes}.toList()..sort();
    final pending = after == null
        ? keys
        : keys.where((key) => key.compareTo(after) > 0).toList();
    final page = pending.take(min(maxKeys, maxKeysLimit)).toList();
    final isTruncated = pending.length > page.length;

    // ETags only for this page's objects: a missing one means reading the file
    final pageFiles = {
      for (final key in page)
        if (files[key] != null && !key.endsWith('/')) key: files[key]!,
    };
    final pageEtags = await objectMeta.etagsOf(
      bucketName: bucketName,
      files: pageFiles,
    );

    return ListObjectsResponse(
      bucketName: bucketName,
      prefix: prefix,
      delimiter: delimiter,
      contents: [
        for (final key in page)
          if (files[key] case (_, final stat))
            FileModel(
              key: key,
              size: key.endsWith('/') ? 0 : stat.size,
              lastModified: stat.modified,
              etag: pageEtags[key] ?? ObjectMetaService.emptyEtag,
            ),
      ],
      commonPrefixes: [
        for (final key in page)
          if (commonPrefixes.contains(key)) key,
      ],
      maxKeys: min(maxKeys, maxKeysLimit),
      continuationToken: continuationToken,
      startAfter: startAfter,
      nextMarker: isTruncated && page.isNotEmpty ? page.last : null,
      isTruncated: isTruncated,
      nextContinuationToken: isTruncated && page.isNotEmpty
          ? base64Url.encode(utf8.encode(page.last))
          : null,
      totalKeys: keys.length,
    );
  }

  String _decodeContinuationToken(String token) {
    try {
      return utf8.decode(base64Url.decode(token));
    } catch (_) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: intl.errors.s3.continuationTokenInvalid,
        resource: token,
      );
    }
  }

  /// Copies an object (CopyObject). The target is overwritten if it exists and
  /// keeps the source's headers, or [headers] when given.
  ///
  /// The storage class is not copied: it is the request's ([storageClass], null
  /// for the standard one), as in S3.
  Future<FileModel> copyFile({
    required String sourceBucket,
    required String sourceKey,
    required String bucketName,
    required String key,
    Map<String, String>? headers,
    String? storageClass,
    CopyConditions conditions = CopyConditions.none,
  }) async {
    for (final bucket in [sourceBucket, bucketName]) {
      if (!S3Validator.isValidBucketName(bucket)) {
        throw S3Exception.invalidBucketName(bucket);
      }
    }
    for (final k in [sourceKey, key]) {
      if (!S3Validator.isValidKey(k) || k.endsWith('/')) {
        throw S3Exception.invalidKey(k);
      }
    }
    // As in S3, copying an object onto itself is only allowed to change its
    // metadata (REPLACE) or its storage class
    final sameObject = sourceBucket == bucketName && sourceKey == key;
    if (sameObject && headers == null && storageClass == null) {
      throw S3Exception(
        S3ErrorCode.invalidRequest,
        message: intl.errors.copy.ontoItself,
        resource: key,
      );
    }
    if (!await Directory(_getBucketPath(sourceBucket)).exists()) {
      throw S3Exception.noSuchBucket(sourceBucket);
    }
    final source = _getFile(sourceBucket, sourceKey);
    if (!await source.exists()) {
      throw S3Exception.noSuchKey(sourceKey);
    }

    if (!await Directory(_getBucketPath(bucketName)).exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }

    final sourceStat = await source.stat();
    final sourceMeta = await objectMeta.metaOf(
      bucketName: sourceBucket,
      key: sourceKey,
      file: source,
      stat: sourceStat,
    );
    conditions.check(
      etag: sourceMeta.etag,
      modified: sourceStat.modified,
      resource: sourceKey,
    );
    final etag = sourceMeta.etag;
    final target = _getFile(bucketName, key);
    if (!sameObject) {
      // Like uploads: copied aside and moved at the end
      final temp = await _tempFile();
      await source.copy(temp.path);
      await replaceFile(temp, target, key: key);
    }
    await objectMeta.save(
      bucketName: bucketName,
      key: key,
      file: target,
      etag: etag,
      headers: {
        for (final MapEntry(key: name, :value)
            in (headers ?? sourceMeta.headers).entries)
          if (name != 'x-amz-storage-class') name: value,
        'x-amz-storage-class': ?storageClass,
      },
    );

    final stat = await target.stat();
    return FileModel(
      key: key,
      size: stat.size,
      lastModified: stat.modified,
      etag: etag,
    );
  }

  /// The content of an object to copy into a part (UploadPartCopy), whole or
  /// only [range] (inclusive positions), if it meets [conditions].
  Future<Stream<List<int>>> readForCopy({
    required String sourceBucket,
    required String sourceKey,
    (int, int)? range,
    CopyConditions conditions = CopyConditions.none,
  }) async {
    final source = await getFile(bucketName: sourceBucket, key: sourceKey);
    final stat = await source.stat();
    final meta = await objectMeta.metaOf(
      bucketName: sourceBucket,
      key: sourceKey,
      file: source,
      stat: stat,
    );
    conditions.check(
      etag: meta.etag,
      modified: stat.modified,
      resource: sourceKey,
    );
    if (range == null) return source.openRead();
    final (start, end) = range;
    if (start > end || end >= stat.size) {
      throw S3Exception(
        S3ErrorCode.invalidRange,
        message: intl.errors.s3.rangeOutsideObject(
          range: '$start-$end',
          size: stat.size,
        ),
        resource: sourceKey,
      );
    }
    return source.openRead(start, end + 1);
  }

  Future<File> getFile({
    required String bucketName,
    required String key,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    if (!S3Validator.isValidKey(key)) {
      throw S3Exception.invalidKey(key);
    }

    // A folder (`photos/`) is its marker: an empty object
    final file = key.endsWith('/')
        ? File(
            p.join(_getBucketPath(bucketName), key, S3Validator.folderMarker),
          )
        : _getFile(bucketName, key);

    if (!await file.exists()) {
      throw S3Exception.noSuchKey(key);
    }

    return file;
  }

  /// The metadata (ETag and headers) of an object already read with [getFile].
  Future<ObjectMetaModel> metaOf({
    required String bucketName,
    required String key,
    required File file,
    FileStat? stat,
  }) => objectMeta.metaOf(
    bucketName: bucketName,
    key: key,
    file: file,
    stat: stat,
  );

  /// Builds the zip in a temp file (without loading the objects in memory).
  /// Use [openAndDeleteTemp] to serve it and delete it afterwards.
  Future<File> zipObjects({
    required String bucketName,
    required List<String> keys,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    for (final key in keys) {
      if (!S3Validator.isValidKey(key)) {
        throw S3Exception.invalidKey(key);
      }
    }

    final bucketPath = _getBucketPath(bucketName);
    final tempDir = await Directory.systemTemp.createTemp('feather-zip-');
    final zipFile = File(p.join(tempDir.path, 'download.zip'));
    final encoder = ZipFileEncoder()..create(zipFile.path);
    int filesAdded = 0;

    try {
      for (final key in keys) {
        final fullPath = p.join(bucketPath, key);
        final type = await FileSystemEntity.type(fullPath);

        if (type == FileSystemEntityType.file) {
          await encoder.addFile(File(fullPath), key);
          filesAdded++;
        } else if (type == FileSystemEntityType.directory) {
          final entities = await Directory(fullPath)
              .list(recursive: true)
              .toList();
          for (final entity in entities) {
            if (entity is File &&
                p.basename(entity.path) != S3Validator.folderMarker) {
              final relativeKey = p
                  .relative(entity.path, from: bucketPath)
                  .replaceAll('\\', '/');
              await encoder.addFile(entity, relativeKey);
              filesAdded++;
            }
          }
        }
      }
      await encoder.close();
    } catch (_) {
      await tempDir.delete(recursive: true);
      rethrow;
    }

    if (filesAdded == 0) {
      await tempDir.delete(recursive: true);
      throw S3Exception(
        S3ErrorCode.noSuchKey,
        message: intl.errors.s3.nothingToDownload,
        resource: bucketName,
      );
    }

    return zipFile;
  }

  /// Stream of the temp file that deletes it (and its folder) when done.
  Stream<List<int>> openAndDeleteTemp(File file) async* {
    try {
      yield* file.openRead();
    } finally {
      await file.parent.delete(recursive: true);
    }
  }

  Future<bool> deleteFile({
    required String bucketName,
    required String key,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    if (!S3Validator.isValidKey(key)) {
      throw S3Exception.invalidKey(key);
    }

    final bucketPath = _getBucketPath(bucketName);

    // As in S3, only the object [key] is deleted: a folder (`photos/`) is its
    // marker and its content is left alone (use [deleteFolder] for that).
    // Deleting something that doesn't exist succeeds (idempotency), and a key
    // without `/` that is a directory is not an object
    final file = key.endsWith('/')
        ? File(p.join(bucketPath, key, S3Validator.folderMarker))
        : File(p.join(bucketPath, key));
    if (await FileSystemEntity.type(file.path) == FileSystemEntityType.file) {
      await _delete(file);
      await _deleteEmptyParents(file.parent, bucketPath);
    }
    await objectMeta.forget(bucketName, key);

    return true;
  }

  /// Deletes the folder [prefix] (`photos/`) with all its content. Not an S3
  /// operation: the console uses it to delete folders.
  Future<void> deleteFolder({
    required String bucketName,
    required String prefix,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    if (!prefix.endsWith('/') || !S3Validator.isValidKey(prefix)) {
      throw S3Exception.invalidKey(prefix);
    }
    final bucketPath = _getBucketPath(bucketName);
    if (!await Directory(bucketPath).exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }

    final dir = Directory(p.join(bucketPath, prefix));
    if (await dir.exists()) {
      await _delete(dir);
      await _deleteEmptyParents(dir.parent, bucketPath);
    }
    await objectMeta.forgetFolder(bucketName, prefix);
    logger.info(
      'Folder deleted',
      fields: {'bucket': bucketName, 'prefix': prefix},
    );
  }

  /// Deletes [entity] (with its content if it is a directory). On Windows an
  /// open file can't be deleted (a download that hasn't closed it yet, the
  /// antivirus scanning a new file): it is retried for a few seconds.
  ///
  /// If it no longer exists (another request deleted it meanwhile) it is not
  /// an error.
  Future<void> _delete(FileSystemEntity entity) async {
    for (var attempt = 1; ; attempt++) {
      try {
        await entity.delete(recursive: true);
        return;
      } on PathNotFoundException {
        return;
      } on PathAccessException {
        if (!Platform.isWindows || attempt == 10) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 50 * attempt));
      }
    }
  }

  Future<DeleteObjectsResponse> deleteObjects({
    required String bucketName,
    required DeleteObjectsRequest request,
  }) async {
    final deleted = <String>[];
    final errors = <DeleteError>[];

    for (final key in request.keys) {
      try {
        await deleteFile(bucketName: bucketName, key: key);
        deleted.add(key);
      } on S3Exception catch (e) {
        errors.add(
          DeleteError(key: key, code: e.code.code, message: e.message),
        );
      } catch (e, stackTrace) {
        // The cause only in the log: it may hold paths of the server
        logger.error(
          'Could not delete an object of a multi-delete',
          error: e,
          stackTrace: stackTrace,
          fields: {'bucket': bucketName, 'key': key},
        );
        errors.add(
          DeleteError(
            key: key,
            code: S3ErrorCode.internalError.code,
            message: intl.errors.s3.objectNotDeleted,
          ),
        );
      }
    }

    return DeleteObjectsResponse(
      deleted: deleted,
      errors: errors,
      quiet: request.quiet,
    );
  }

  Future<void> _deleteEmptyParents(Directory dir, String bucketPath) async {
    final currentPath = p.canonicalize(dir.path);
    final rootPath = p.canonicalize(bucketPath);

    // Stops at the bucket itself or outside it
    if (!currentPath.startsWith(rootPath) || currentPath == rootPath) {
      return;
    }

    // Just cleanup (an empty folder without a marker isn't listed): if it
    // fails, the object is already deleted and the folder stays. Not
    // `recursive`, so it never takes what another request has just uploaded.
    // With parallel deletes another request may have removed it already or be
    // removing it (on Windows: access denied meanwhile, and "not empty" while
    // its files finish being deleted)
    for (var attempt = 1; ; attempt++) {
      try {
        await dir.delete();
        break;
      } on PathAccessException {
        if (!Platform.isWindows || attempt == 10 || !await dir.exists()) {
          return;
        }
        await Future<void>.delayed(Duration(milliseconds: 20 * attempt));
      } on FileSystemException {
        return;
      }
    }
    // Then tries the parent
    await _deleteEmptyParents(dir.parent, bucketPath);
  }

  String _getBucketPath(String bucketName) {
    return p.join(env.storageVolumePath, bucketName);
  }

  File _getFile(String bucketName, String key) {
    final folderPath = _getBucketPath(bucketName);
    return File(p.join(folderPath, key));
  }
}
