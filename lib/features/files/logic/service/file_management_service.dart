import 'dart:io';

import 'package:feather_io/feather.dart';
import 'package:path/path.dart' as p;

class FileManagementService {
  final bool createBucketIfNotExist;

  FileManagementService({this.createBucketIfNotExist = true});

  Future<bool> createBucket({required String bucketName}) async {
    //valido que el key sea valido
    if (!isSafeKey(bucketName)) {
      throw BadRequestException(body: 'El bucket $bucketName no es valido');
    }

    //creo el bucket si no existe
    if (createBucketIfNotExist) {
      final bucketDir = Directory(_getBucketPath(bucketName));
      await bucketDir.create(recursive: true);
    }

    return true;
  }

  Future<bool> uploadFile({
    required String bucketName,
    required String key,
    required Stream<List<int>> binary,
  }) async {
    //valido que el key sea valido
    if (!isSafeKey(bucketName)) {
      throw BadRequestException(body: 'El bucket $key no es valido');
    }
    //valido que el key sea valido
    if (!isSafeKey(key)) {
      throw BadRequestException(body: 'El key $key no es valido');
    }

    //creo el bucket si no existe
    if (createBucketIfNotExist) {
      final bucketDir = Directory(_getBucketPath(bucketName));
      await bucketDir.create(recursive: true);
    }

    final file = _getFile(bucketName, key);

    try {
      // 1. Abrimos el archivo en modo escritura como un IOSink (Stream)
      final sink = file.openWrite();

      // 2. Conectamos el stream del request directamente al archivo
      // request.read() nos da los bytes a medida que llegan por la red
      // El method .pipe() cierra el sink automáticamente al terminar
      await binary.cast<List<int>>().pipe(sink);

      return true;
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }

      return false;
    }
  }

  Future<List<FileModel>> listFiles({required String bucketName}) async {
    final dir = Directory(_getBucketPath(bucketName));

    if (!await dir.exists()) {
      return [];
    }

    // Listamos los archivos del directorio.
    // recursive: false (estilo S3 básico, solo lo que está en la raíz)
    final List<FileSystemEntity> entities = await dir
        .list(recursive: false)
        .toList();

    // Filtramos para obtener solo ARCHIVOS (ignorando subcarpetas si las hubiera)
    final List<FileModel> filesList = [];

    for (var entity in entities) {
      if (entity is File) {
        final stat = await entity.stat();

        filesList.add(
          FileModel(
            name: p.basename(entity.path),
            size: stat.size,
            lastModified: stat.modified,
          ),
        );
      }
    }

    return filesList;
  }

  Future<File> getFile({
    required String bucketName,
    required String key,
  }) async {
    if (!isSafeKey(bucketName)) {
      throw BadRequestException(body: 'El bucket $bucketName no es valido');
    }
    if (!isSafeKey(key)) {
      throw BadRequestException(body: 'El key $key no es valido');
    }

    final file = _getFile(bucketName, key);

    if (!await file.exists()) {
      throw NotFoundException(body: 'El archivo "$key" no existe.');
    }

    return file;
  }

  Future<bool> deleteFile({
    required String bucketName,
    required String key,
  }) async {
    if (!isSafeKey(key)) {
      throw BadRequestException(body: 'El key $bucketName no es valido');
    }

    final file = _getFile(bucketName, key);

    if (!await file.exists()) {
      throw NotFoundException(body: 'El archivo "$key" no existe.');
    }

    await file.delete();
    return true;
  }

  String _getBucketPath(String bucketName) {
    return p
        .join(env.storagePath, bucketName)
        .replaceAll('/', '_')
        .replaceAll('\\', '_');
  }

  File _getFile(String bucketName, String key) {
    final folderPath = _getBucketPath(bucketName);
    //si pasan un key con /, algo como: {test/file/123.jgp}, se convierten los / en _ para que no se creen subcarpetas
    final safeKey = key.replaceAll('/', '_').replaceAll('\\', '_');
    return File(p.join(folderPath, safeKey));
  }

  /// Valida si una Key de tipo S3 es segura para procesarse en el sistema.
  /// Devuelve [true] si la ruta es limpia y segura, [false] si detecta riesgos de Path Traversal.
  bool isSafeKey(String rawKey) {
    // 1. Descartar strings vacíos o que solo contienen espacios
    if (rawKey.trim().isEmpty) return false;

    // 2. Control de caracteres sospechosos en la URL o nombres de archivo
    // Bloqueamos secuencias explícitas de subida de nivel (../ o ..\)
    // También bloqueamos caracteres nulos (%00 o \x00) que se usan para truncar rutas en algunos sistemas
    if (rawKey.contains('..') ||
        rawKey.contains(r'..\') ||
        rawKey.contains('\x00') ||
        rawKey.contains('%00')) {
      return false;
    }

    try {
      // 3. Normalización con la clase Uri de Dart
      // Esto resuelve barras duplicadas (ej: fotos//secreto.pdf) y limpia la estructura
      final uri = Uri.parse(rawKey);

      // Si la Uri detecta que tiene un esquema (como http://) o un host, la rechazamos
      // porque una Key de S3 solo debe ser un path relativo (ej: usuarios/123/foto.jpg)
      if (uri.hasScheme || uri.hasAuthority) return false;

      // 4. Verificación de segmentos
      // Si después de limpiar la ruta, algún segmento se convirtió en '.' o '..', es inválido
      for (var segment in uri.pathSegments) {
        if (segment == '.' || segment == '..') return false;
      }

      // 5. Simulación de ruta física (La prueba definitiva)
      // Simulamos una raíz falsa y verificamos que el path final siga dentro de ella
      const fakeRoot = '/safe_root';
      final fullPath = p.join(fakeRoot, rawKey);

      // canonicalize resuelve cualquier truco raro que haya pasado los filtros anteriores
      final canonicalRoot = p.canonicalize(fakeRoot);
      final canonicalPath = p.canonicalize(fullPath);

      // Si la ruta final no empieza con la raíz, significa que logró escapar
      if (!canonicalPath.startsWith(canonicalRoot)) {
        return false;
      }

      // Si pasó todos los filtros, la Key es segura
      return true;
    } catch (e) {
      // Si Uri.parse falla porque la cadena está malformada, la consideramos insegura
      return false;
    }
  }
}
