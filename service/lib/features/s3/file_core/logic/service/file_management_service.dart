import 'dart:io';

import 'package:archive/archive_io.dart';
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

    // S3 requiere que el bucket esté vacío para ser borrado
    final entities = await dir.list().toList();
    if (entities.isNotEmpty) {
      throw S3Exception(
        S3ErrorCode.bucketNotEmpty,
        message: 'El bucket "$bucketName" no está vacío y no puede ser borrado.',
        resource: bucketName,
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
          throw S3Exception(
            S3ErrorCode.entityTooLarge,
            message: 'El archivo excede el tamaño máximo permitido.',
            resource: key,
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

  Future<ListObjectsResponse> listFiles({
    required String bucketName,
    String? prefix,
    String? delimiter,
  }) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    final bucketPath = _getBucketPath(bucketName);
    final dir = Directory(bucketPath);

    if (!await dir.exists()) {
      throw S3Exception.noSuchBucket(bucketName);
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
      throw S3Exception.invalidBucketName(bucketName);
    }
    if (!S3Validator.isValidKey(key)) {
      throw S3Exception.invalidKey(key);
    }

    final file = _getFile(bucketName, key);

    if (!await file.exists()) {
      throw S3Exception.noSuchKey(key);
    }

    return file;
  }

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
            if (entity is File) {
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
      } on S3Exception catch (e) {
        errors.add(DeleteError(key: key, code: e.code.code, message: e.message));
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
