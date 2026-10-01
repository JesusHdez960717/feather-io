import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';

enum TransferDirection { upload, download }

enum TransferStatus {
  queued,
  running,
  done,
  failed,
  cancelled;

  ///En cola o en curso
  bool get isActive => this == queued || this == running;
}

///Una subida o una descarga de la cola de transferencias
class TransferTask {
  final String id;
  final TransferDirection direction;
  final String bucket;

  ///Nombre que se muestra: el del fichero subido o el del zip descargado
  final String name;

  ///Carpeta de destino (subida) u origen (descarga) dentro del bucket
  ///(`fotos/2026/`), vacia en la raiz
  final String folder;

  ///Subida: la key de destino y el fichero, que se guarda para reintentar
  final String? key;
  final XFile? file;

  ///Descarga: las keys que van en el zip
  final List<String> keys;

  ///Bytes totales; en una descarga, 0 hasta que el servicio manda el zip
  final int size;

  ///Bytes enviados o recibidos
  final int transferred;
  final TransferStatus status;
  final GlobalException? error;

  const TransferTask({
    required this.id,
    required this.direction,
    required this.bucket,
    required this.name,
    required this.folder,
    this.key,
    this.file,
    this.keys = const [],
    this.size = 0,
    this.transferred = 0,
    this.status = TransferStatus.queued,
    this.error,
  });

  bool get isUpload => direction == TransferDirection.upload;

  ///De 0 a 1
  double get progress {
    if (status == TransferStatus.done) return 1;
    return size == 0 ? 0 : (transferred / size).clamp(0, 1);
  }

  TransferTask copyWith({
    int? size,
    int? transferred,
    TransferStatus? status,
    GlobalException? error,
    bool clearError = false,
  }) {
    return TransferTask(
      id: id,
      direction: direction,
      bucket: bucket,
      name: name,
      folder: folder,
      key: key,
      file: file,
      keys: keys,
      size: size ?? this.size,
      transferred: transferred ?? this.transferred,
      status: status ?? this.status,
      error: clearError ? null : error ?? this.error,
    );
  }

  ///Carpeta que contiene [key] (`fotos/2026/` para `fotos/2026/a.jpg` y para
  ///la carpeta `fotos/2026/b/`)
  static String parentFolder(String key) {
    final path = key.endsWith('/') ? key.substring(0, key.length - 1) : key;
    return path.substring(0, path.lastIndexOf('/') + 1);
  }
}
