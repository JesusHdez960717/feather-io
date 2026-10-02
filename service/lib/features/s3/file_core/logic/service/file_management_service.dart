import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:service/feather.dart';

class FileManagementService {
  final int maxFileSize;
  final ObjectMetaService objectMeta;

  FileManagementService({
    this.maxFileSize = 5 * 1024 * 1024 * 1024, // 5GB por defecto (límite S3)
    ObjectMetaService? objectMeta,
  }) : objectMeta = objectMeta ?? ObjectMetaService();

  Future<bool> createBucket({required String bucketName}) async {
    // Valido el nombre del bucket con reglas S3
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception(
        S3ErrorCode.invalidBucketName,
        message:
            'El nombre del bucket "$bucketName" no es válido. Debe tener entre 3 y 63 caracteres, usar solo minúsculas, números, puntos o guiones, y empezar/terminar con letra o número.',
        resource: bucketName,
      );
    }

    //como S3, crear un bucket que ya existe es un 409
    final bucketDir = Directory(_getBucketPath(bucketName));
    if (await bucketDir.exists()) {
      throw S3Exception(
        S3ErrorCode.bucketAlreadyOwnedByYou,
        message: 'El bucket "$bucketName" ya existe.',
        resource: bucketName,
      );
    }

    //creo el bucket físicamente
    await bucketDir.create(recursive: true);

    return true;
  }

  Future<bool> deleteBucketPhysical(String bucketName) async {
    // Valido el nombre del bucket
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }

    final bucketPath = _getBucketPath(bucketName);
    final dir = Directory(bucketPath);

    if (!await dir.exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }

    // S3 requiere que el bucket esté vacío para ser borrado. Las carpetas
    // vacias (solo con su marcador) no son objetos y no lo impiden
    final hasObjects = await dir
        .list(recursive: true)
        .any(
          (entity) =>
              entity is File &&
              p.basename(entity.path) != S3Validator.folderMarker,
        );
    if (hasObjects) {
      throw S3Exception(
        S3ErrorCode.bucketNotEmpty,
        message:
            'El bucket "$bucketName" no está vacío y no puede ser borrado.',
        resource: bucketName,
      );
    }

    await dir.delete(recursive: true);
    await objectMeta.forgetBucket(bucketName);
    return true;
  }

  Future<bool> bucketExists(String bucketName) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    return Directory(_getBucketPath(bucketName)).exists();
  }

  /// Borra todo el contenido del bucket y deja la carpeta vacia
  Future<void> emptyBucket(String bucketName) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    final dir = Directory(_getBucketPath(bucketName));
    if (!await dir.exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }
    await for (final entity in dir.list()) {
      await entity.delete(recursive: true);
    }
    await objectMeta.forgetBucket(bucketName);
  }

  /// Guarda el objeto con sus [headers] (`Content-Type`, `x-amz-meta-*`…) y
  /// devuelve su ETag (el md5 del contenido)
  Future<String> uploadFile({
    required String bucketName,
    required String key,
    required Stream<List<int>> binary,
    int? contentLength,
    Map<String, String> headers = const {},
  }) async {
    // Valido el nombre del bucket
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    // Valido el key con reglas S3
    if (!S3Validator.isValidKey(key)) {
      throw S3Exception.invalidKey(key);
    }

    // Validar tamaño máximo si se proporciona el content-length
    if (contentLength != null && contentLength > maxFileSize) {
      throw S3Exception(
        S3ErrorCode.entityTooLarge,
        message:
            'El archivo excede el tamaño máximo permitido de ${maxFileSize / (1024 * 1024)} MB',
        resource: key,
      );
    }

    //como en S3, el bucket tiene que existir; las subcarpetas se crean solas
    if (!await Directory(_getBucketPath(bucketName)).exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }

    // Una key terminada en '/' es una carpeta, como en la consola de S3: se
    // crea vacia con su marcador y el cuerpo (vacio) se descarta
    if (key.endsWith('/')) {
      await binary.drain<void>();
      final folder = Directory(p.join(_getBucketPath(bucketName), key));
      await folder.create(recursive: true);
      await File(p.join(folder.path, S3Validator.folderMarker)).create();
      return ObjectMetaService.emptyEtag;
    }

    final file = _getFile(bucketName, key);
    await file.parent.create(recursive: true);

    int bytesRead = 0;
    try {
      final sink = file.openWrite();
      final hasher = Md5Tap();

      // Transformamos el stream para contar bytes y validar el límite en tiempo real
      final monitoredStream = binary.map((chunk) {
        bytesRead += chunk.length;
        if (bytesRead > maxFileSize) {
          throw S3Exception(
            S3ErrorCode.entityTooLarge,
            message: 'El archivo excede el tamaño máximo permitido.',
            resource: key,
          );
        }
        return chunk;
      });

      await hasher.bind(monitoredStream).pipe(sink);

      final etag = hasher.close();
      await objectMeta.save(
        bucketName: bucketName,
        key: key,
        file: file,
        etag: etag,
        headers: headers,
      );
      return etag;
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  /// Maximo de claves por pagina en [listFiles], como en S3
  static const int maxKeysLimit = 1000;

  /// Lista los objetos del bucket ordenados por key. Con [delimiter] agrupa lo
  /// que hay por debajo en prefijos comunes. Pagina como ListObjectsV2: como
  /// mucho [maxKeys] claves (objetos + prefijos) y, si hay mas, un token para
  /// pedir la pagina siguiente
  Future<ListObjectsResponse> listFiles({
    required String bucketName,
    String? prefix,
    String? delimiter,
    int maxKeys = maxKeysLimit,
    String? continuationToken,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    if (maxKeys < 0) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: 'max-keys no puede ser negativo.',
        resource: bucketName,
      );
    }
    final startAfter = continuationToken == null
        ? null
        : _decodeContinuationToken(continuationToken);

    final bucketPath = _getBucketPath(bucketName);
    final dir = Directory(bucketPath);

    if (!await dir.exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }

    // Listamos los archivos del directorio recursivamente para soportar subcarpetas
    final List<FileSystemEntity> entities = await dir
        .list(recursive: true)
        .toList();

    final Map<String, (File, FileStat)> files = {};
    final Set<String> commonPrefixes = {};

    final normalizedPrefix = prefix ?? '';

    for (var entity in entities) {
      if (entity is! File) continue;

      // Obtenemos la ruta relativa al bucket para usarla como key (ej: files/test/123.jpg)
      final relative = p
          .relative(entity.path, from: bucketPath)
          .replaceAll('\\', '/');

      // El marcador de una carpeta creada a mano se lista como la key "carpeta/"
      final isFolder = p.posix.basename(relative) == S3Validator.folderMarker;
      final folder = p.posix.dirname(relative);
      if (isFolder && folder == '.') continue;
      final key = isFolder ? '$folder/' : relative;

      // Filtrar por prefijo
      if (!key.startsWith(normalizedPrefix)) continue;

      if (delimiter != null && delimiter.isNotEmpty) {
        // Si hay delimitador, buscamos si hay uno después del prefijo
        final remainingKey = key.substring(normalizedPrefix.length);
        final delimiterIndex = remainingKey.indexOf(delimiter);

        if (delimiterIndex != -1) {
          // Es una "carpeta" (Common Prefix)
          final commonPrefix =
              normalizedPrefix + remainingKey.substring(0, delimiterIndex + 1);
          commonPrefixes.add(commonPrefix);
          continue;
        }
      }

      files[key] = (entity, await entity.stat());
    }

    // Objetos y prefijos van juntos y ordenados, como en S3, y se pagina sobre
    // ese orden: la pagina empieza despues de la ultima key de la anterior
    final keys = {...files.keys, ...commonPrefixes}.toList()..sort();
    final pending = startAfter == null
        ? keys
        : keys.where((key) => key.compareTo(startAfter) > 0).toList();
    final page = pending.take(min(maxKeys, maxKeysLimit)).toList();
    final isTruncated = pending.length > page.length;

    //el ETag solo de los objetos de esta pagina: si falta hay que leer el fichero
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
        message: 'El continuation-token no es válido.',
        resource: token,
      );
    }
  }

  /// Copia un objeto (CopyObject). El destino se sobrescribe si existe y se
  /// queda con las cabeceras del origen, o con [headers] si se indican
  Future<FileModel> copyFile({
    required String sourceBucket,
    required String sourceKey,
    required String bucketName,
    required String key,
    Map<String, String>? headers,
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
    if (sourceBucket == bucketName && sourceKey == key) {
      throw S3Exception(
        S3ErrorCode.invalidRequest,
        message: 'El origen y el destino de la copia son el mismo objeto.',
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

    final sourceMeta = await objectMeta.metaOf(
      bucketName: sourceBucket,
      key: sourceKey,
      file: source,
    );
    final etag = sourceMeta.etag;
    final target = _getFile(bucketName, key);
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    await objectMeta.save(
      bucketName: bucketName,
      key: key,
      file: target,
      etag: etag,
      headers: headers ?? sourceMeta.headers,
    );

    final stat = await target.stat();
    return FileModel(
      key: key,
      size: stat.size,
      lastModified: stat.modified,
      etag: etag,
    );
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

    //una carpeta (`fotos/`) es su marcador: un objeto vacio
    final file = key.endsWith('/')
        ? File(p.join(_getBucketPath(bucketName), key, S3Validator.folderMarker))
        : _getFile(bucketName, key);

    if (!await file.exists()) {
      throw S3Exception.noSuchKey(key);
    }

    return file;
  }

  /// Los metadatos (ETag y cabeceras) de un objeto ya leido con [getFile]
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

  /// Genera el zip en un fichero temporal (sin cargar los objetos en memoria).
  /// Usar [openAndDeleteTemp] para servirlo y borrarlo al terminar.
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
        message: 'No se encontraron archivos para descargar.',
        resource: bucketName,
      );
    }

    return zipFile;
  }

  /// Stream del fichero temporal que lo borra (junto a su carpeta) al terminar.
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

    final fullPath = p.join(_getBucketPath(bucketName), key);
    final type = await FileSystemEntity.type(fullPath);

    if (type == FileSystemEntityType.notFound) {
      // En S3, borrar un objeto que no existe se considera éxito (idempotencia)
      return true;
    }

    if (type == FileSystemEntityType.directory) {
      // Si es un directorio, borramos recursivamente (comportamiento de carpeta)
      await Directory(fullPath).delete(recursive: true);
      await objectMeta.forgetFolder(bucketName, key);
    } else {
      // Si es un archivo normal
      await File(fullPath).delete();
      await objectMeta.forget(bucketName, key);
    }

    // Limpieza recursiva de carpetas vacías (si aplica)
    await _deleteEmptyParents(
      Directory(fullPath).parent,
      _getBucketPath(bucketName),
    );

    return true;
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
      } catch (e) {
        errors.add(
          DeleteError(
            key: key,
            code: S3ErrorCode.internalError.code,
            message: e.toString(),
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

    // Si el directorio actual es el bucket o está fuera de él, nos detenemos
    if (!currentPath.startsWith(rootPath) || currentPath == rootPath) {
      return;
    }

    if (await dir.exists()) {
      final entities = await dir.list().toList();
      if (entities.isEmpty) {
        await dir.delete();
        // Intentamos borrar el padre recursivamente
        await _deleteEmptyParents(dir.parent, bucketPath);
      }
    }
  }

  String _getBucketPath(String bucketName) {
    return p.join(env.storageVolumePath, bucketName);
  }

  File _getFile(String bucketName, String key) {
    final folderPath = _getBucketPath(bucketName);
    return File(p.join(folderPath, key));
  }
}
