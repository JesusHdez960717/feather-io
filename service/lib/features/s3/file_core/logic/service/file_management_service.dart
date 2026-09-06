import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:service/feather.dart';

class FileManagementService {
  final bool createBucketIfNotExist;
  final int maxFileSize;

  FileManagementService({
    this.createBucketIfNotExist = true,
    this.maxFileSize = 5 * 1024 * 1024 * 1024, // 5GB por defecto (límite S3)
  });

  Future<bool> createBucket({required String bucketName}) async {
    // Valido el nombre del bucket con reglas S3
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw BadRequestException(
        body:
            'El nombre del bucket "$bucketName" no es válido. Debe tener entre 3 y 63 caracteres, usar solo minúsculas, números, puntos o guiones, y empezar/terminar con letra o número.',
      );
    }

    //creo el bucket físicamente
    final bucketDir = Directory(_getBucketPath(bucketName));
    if (!await bucketDir.exists()) {
      await bucketDir.create(recursive: true);
    }

    return true;
  }

  Future<bool> deleteBucketPhysical(String bucketName) async {
    // Valido el nombre del bucket
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw BadRequestException(body: 'El bucket $bucketName no es valido');
    }

    final bucketPath = _getBucketPath(bucketName);
    final dir = Directory(bucketPath);

    if (!await dir.exists()) {
      throw NotFoundException(body: 'El bucket "$bucketName" no existe.');
    }

    // S3 requiere que el bucket esté vacío para ser borrado
    final entities = await dir.list().toList();
    if (entities.isNotEmpty) {
      // Usamos una excepción que el controlador mapeará a BucketNotEmpty (409)
      throw ConflictException(
        body: 'El bucket "$bucketName" no está vacío y no puede ser borrado.',
      );
    }

    await dir.delete();
    return true;
  }

  Future<bool> uploadFile({
    required String bucketName,
    required String key,
    required Stream<List<int>> binary,
    int? contentLength,
  }) async {
    // Valido el nombre del bucket
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw BadRequestException(body: 'El bucket $bucketName no es valido');
    }
    // Valido el key con reglas S3
    if (!S3Validator.isValidKey(key)) {
      throw BadRequestException(
        body: 'El key $key no es valido o contiene caracteres prohibidos.',
      );
    }

    // Validar tamaño máximo si se proporciona el content-length
    if (contentLength != null && contentLength > maxFileSize) {
      throw BadRequestException(
        body:
            'El archivo excede el tamaño máximo permitido de ${maxFileSize / (1024 * 1024)} MB',
      );
    }

    final file = _getFile(bucketName, key);

    //creo el bucket y las subcarpetas si no existen
    if (createBucketIfNotExist) {
      await file.parent.create(recursive: true);
    }

    int bytesRead = 0;
    try {
      final sink = file.openWrite();

      // Transformamos el stream para contar bytes y validar el límite en tiempo real
      final monitoredStream = binary.map((chunk) {
        bytesRead += chunk.length;
        if (bytesRead > maxFileSize) {
          throw BadRequestException(
            body: 'El archivo excede el tamaño máximo permitido.',
          );
        }
        return chunk;
      });

      await monitoredStream.pipe(sink);

      return true;
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  Future<List<BucketModel>> listBuckets() async {
    final storageDir = Directory(env.storageVolumePath);
    if (!await storageDir.exists()) {
      return [];
    }

    final List<BucketModel> buckets = [];
    final List<FileSystemEntity> entities = await storageDir.list().toList();

    for (var entity in entities) {
      if (entity is Directory) {
        final bucketName = p.basename(entity.path);
        if (!S3Validator.isValidBucketName(bucketName)) continue;

        final stat = await entity.stat();

        // Calculamos stats del bucket
        int totalSize = 0;
        int objectCount = 0;

        final bucketEntities = await entity.list(recursive: true).toList();
        for (var bucketEntity in bucketEntities) {
          if (bucketEntity is File) {
            objectCount++;
            totalSize += await bucketEntity.length();
          }
        }

        buckets.add(
          BucketModel(
            name: bucketName,
            objectCount: objectCount,
            size: totalSize,
            creationDate: stat.changed,
          ),
        );
      }
    }

    return buckets;
  }

  Future<ListObjectsResponse> listFiles({
    required String bucketName,
    String? prefix,
    String? delimiter,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw BadRequestException(body: 'El bucket $bucketName no es valido');
    }
    final bucketPath = _getBucketPath(bucketName);
    final dir = Directory(bucketPath);

    if (!await dir.exists()) {
      throw NotFoundException(body: 'El bucket "$bucketName" no existe.');
    }

    // Listamos los archivos del directorio recursivamente para soportar subcarpetas
    final List<FileSystemEntity> entities = await dir
        .list(recursive: true)
        .toList();

    final List<FileModel> filesList = [];
    final Set<String> commonPrefixes = {};

    final normalizedPrefix = prefix ?? '';

    for (var entity in entities) {
      if (entity is File) {
        // Obtenemos la ruta relativa al bucket para usarla como key (ej: files/test/123.jpg)
        final key = p
            .relative(entity.path, from: bucketPath)
            .replaceAll('\\', '/');

        // Filtrar por prefijo
        if (!key.startsWith(normalizedPrefix)) continue;

        if (delimiter != null && delimiter.isNotEmpty) {
          // Si hay delimitador, buscamos si hay uno después del prefijo
          final remainingKey = key.substring(normalizedPrefix.length);
          final delimiterIndex = remainingKey.indexOf(delimiter);

          if (delimiterIndex != -1) {
            // Es una "carpeta" (Common Prefix)
            final commonPrefix =
                normalizedPrefix +
                remainingKey.substring(0, delimiterIndex + 1);
            commonPrefixes.add(commonPrefix);
            continue;
          }
        }

        final stat = await entity.stat();
        filesList.add(
          FileModel(key: key, size: stat.size, lastModified: stat.modified),
        );
      }
    }

    return ListObjectsResponse(
      bucketName: bucketName,
      prefix: prefix,
      delimiter: delimiter,
      contents: filesList,
      commonPrefixes: commonPrefixes.toList()..sort(),
    );
  }

  Future<File> getFile({
    required String bucketName,
    required String key,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw BadRequestException(body: 'El bucket $bucketName no es valido');
    }
    if (!S3Validator.isValidKey(key)) {
      throw BadRequestException(body: 'El key $key no es valido');
    }

    final file = _getFile(bucketName, key);

    if (!await file.exists()) {
      throw NotFoundException(body: 'El archivo "$key" no existe.');
    }

    return file;
  }

  Future<List<int>> zipObjects({
    required String bucketName,
    required List<String> keys,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw BadRequestException(body: 'El bucket $bucketName no es valido');
    }

    final bucketPath = _getBucketPath(bucketName);
    final archive = Archive();

    for (final key in keys) {
      final fullPath = p.join(bucketPath, key);
      final type = await FileSystemEntity.type(fullPath);

      if (type == FileSystemEntityType.file) {
        final file = File(fullPath);
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(key, bytes.length, bytes));
      } else if (type == FileSystemEntityType.directory) {
        final dir = Directory(fullPath);
        final entities = await dir.list(recursive: true).toList();
        for (final entity in entities) {
          if (entity is File) {
            final relativeKey = p
                .relative(entity.path, from: bucketPath)
                .replaceAll('\\', '/');
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(relativeKey, bytes.length, bytes));
          }
        }
      }
    }

    if (archive.isEmpty) {
      throw NotFoundException(
        body: 'No se encontraron archivos para descargar.',
      );
    }

    return ZipEncoder().encode(archive);
  }

  Future<bool> deleteFile({
    required String bucketName,
    required String key,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw BadRequestException(body: 'El bucket $bucketName no es valido');
    }
    if (!S3Validator.isValidKey(key)) {
      throw BadRequestException(body: 'El key $key no es valido');
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
    } else {
      // Si es un archivo normal
      await File(fullPath).delete();
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
      } catch (e) {
        errors.add(
          DeleteError(key: key, code: 'InternalError', message: e.toString()),
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
