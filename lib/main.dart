import 'dart:io';
import 'dart:math';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:winter/winter.dart';

import 'feather.dart';

void main() async {
  Env env = Env();

  await Winter.start(
    config: ServerConfig(port: 8080),
    context: BuildContext(objectMapper: buildObjectMapper(), env: env),
    globalFilterConfig: FilterConfig([SecurityFilter(env)]),
    router: WinterRouter(
      routes: [
        Route(
          path: '/test',
          method: HttpMethod.get,
          handler: (request) async {
            return ResponseEntity.ok(body: 'Test OK');
          },
        ),
        Route.post(
          path: '/upload',
          handler: (request) async {
            String fileName = '${Random().nextInt(999999999)}.jpg';

            // Validamos y limpiamos el path para evitar Path Traversal (seguridad)
            final safeFileName = p.basename(fileName);

            final folder = 'bucket/test/';
            final folderPath = p.join(env.storagePath, folder);
            await Directory(folderPath).create(recursive: true);

            final filePath = p.join(env.storagePath, folder + safeFileName);
            final file = File(filePath);

            try {
              print('Recibiendo archivo: $safeFileName...');

              // 1. Abrimos el archivo en modo escritura como un IOSink (Stream)
              final sink = file.openWrite();

              // 2. Conectamos el stream del request directamente al archivo
              // request.read() nos da los bytes a medida que llegan por la red
              // El method .pipe() cierra el sink automáticamente al terminar
              await request.read().cast<List<int>>().pipe(sink);

              print('Archivo guardado con éxito en: $filePath');
              return ResponseEntity.ok(
                body: 'Archivo "$safeFileName" subido correctamente.',
              );
            } catch (e) {
              print('Error al guardar el archivo: $e');

              // Limpieza si el archivo quedó a medias
              if (await file.exists()) {
                await file.delete();
              }

              return ResponseEntity.internalServerError(
                body: 'Error interno al guardar el archivo.',
              );
            }
          },
        ),
        Route.get(
          path: '/list',
          handler: (request) async {
            final folder = 'bucket/test/';
            final folderPath = p.join(env.storagePath, folder);
            final dir = Directory(folderPath);

            // Verificamos si la carpeta existe, si no, devolvemos lista vacía
            if (!await dir.exists()) {
              return ResponseEntity.ok(
                body: [],
                headers: {'Content-Type': 'application/json'},
              );
            }

            // Listamos los archivos del directorio.
            // recursive: false (estilo S3 básico, solo lo que está en la raíz)
            final List<FileSystemEntity> entities = await dir
                .list(recursive: false)
                .toList();

            // Filtramos para obtener solo ARCHIVOS (ignorando subcarpetas si las hubiera)
            final List<Map<String, dynamic>> filesList = [];

            for (var entity in entities) {
              if (entity is File) {
                final stat = await entity.stat();

                filesList.add({
                  'name': p.basename(entity.path),
                  'size_bytes': stat.size,
                  'last_modified': stat.modified.toIso8601String(),
                });
              }
            }

            // Devolvemos la respuesta como JSON
            return ResponseEntity.ok(
              body: filesList,
              headers: {
                'Content-Type': 'application/json',
                'X-Object-Count': filesList.length.toString(),
              },
            );
          },
        ),
        Route.get(
          path: '/{file-name}',
          handler: (request) async {
            String fileName = request.pathParams['file-name']!;

            final folder = 'bucket/test/';
            final folderPath = p.join(env.storagePath, folder);
            final filePath = p.join(folderPath, fileName);
            final file = File(filePath);

            // 1. Verificar si el archivo realmente existe en /data
            if (!await file.exists()) {
              return ResponseEntity.notFound(
                body: 'El archivo "$fileName" no existe en el servidor.',
              );
            }
            try {
              // 2. Detectar el Content-Type correcto (ej: image/jpeg, image/png, application/pdf)
              // Si no lo reconoce, por defecto usamos 'application/octet-stream' (binario genérico)
              final contentType =
                  lookupMimeType(filePath) ?? 'application/octet-stream';

              print('Sirviendo archivo: $fileName como $contentType');

              // 3. Responder enviando el archivo como un Stream de bytes
              // request.read() del post era un stream de entrada, file.openRead() es un stream de salida.
              return ResponseEntity.ok(
                body: file.openRead(),
                headers: {
                  'Content-Type': contentType,
                  'Content-Length': (await file.length()).toString(),
                },
              );
            } catch (e) {
              return ResponseEntity.internalServerError(
                body: 'Error al abrir el archivo.',
              );
            }
          },
        ),
        Route.delete(
          path: '/{file-name}',
          handler: (request) async {
            String fileName = request.pathParams['file-name']!;
            final safeFileName = p.basename(fileName);

            final folder = 'bucket/test/';
            final folderPath = p.join(env.storagePath, folder);
            final filePath = p.join(folderPath, safeFileName);
            final file = File(filePath);

            if (!await file.exists()) {
              return ResponseEntity.notFound(
                body: 'El archivo "$safeFileName" no existe.',
              );
            }

            try {
              await file.delete();
              print('Archivo eliminado: $safeFileName');
              return ResponseEntity.ok(
                body: 'Archivo "$safeFileName" eliminado correctamente.',
              );
            } catch (e) {
              print('Error al eliminar el archivo: $e');
              return ResponseEntity.internalServerError(
                body: 'Error al eliminar el archivo.',
              );
            }
          },
        ),
      ],
    ),
  );
}
