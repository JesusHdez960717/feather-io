import 'dart:io';

import 'package:service/feather.dart';

///Tamaño maximo por defecto de un objeto (5 GiB, el limite de un `PUT` en S3)
const int defaultMaxObjectSize = 5 * 1024 * 1024 * 1024;

extension ExtendedEnv on Env {
  String get secret => find<String>('FEATHER_SECRET', required: true)!;

  String get access => find<String>('FEATHER_ACCESS', required: true)!;

  String get jwtSecret => find<String>('JWT_SECRET', required: true)!;

  String get storageVolumePath =>
      find<String>('STORAGE_VOLUME_PATH', required: true)!;

  ///Tamaño maximo (en bytes) de un objeto subido con `PUT`
  int get maxObjectSize =>
      find<int>('MAX_OBJECT_SIZE', required: false) ?? defaultMaxObjectSize;

  ///URL publica del servicio (`https://s3.example.com`), para las URLs
  ///prefirmadas. Sin ella se usan el esquema y el `Host` de la peticion, que
  ///detras de un proxy con HTTPS darian `http://`. Solo esquema, host y puerto:
  ///la ruta forma parte de la firma
  Uri? get publicUrl {
    final raw = find<String>('PUBLIC_URL', required: false);
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        (uri.path.isEmpty || uri.path == '/') &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        uri.userInfo.isEmpty;
    if (!valid) {
      throw ArgumentError.value(
        raw,
        'PUBLIC_URL',
        'tiene que ser esquema, host y puerto, sin ruta (https://s3.example.com)',
      );
    }
    return uri;
  }

  ///Proxies propios delante del servicio que añaden su entrada a
  ///`X-Forwarded-For`; con 0 (por defecto) se usa la IP de la conexion
  int get trustedProxies => find<int>('TRUSTED_PROXIES', required: false) ?? 0;

  ///Peticiones por IP en cada ventana de [rateLimitWindowSeconds] (limite
  ///general); 0 lo desactiva. Alto por defecto: los clientes S3 mandan rafagas
  ///(subidas por partes, `sync` de muchos ficheros)
  int get rateLimitRequests =>
      find<int>('RATE_LIMIT_REQUESTS', required: false) ?? 2000;

  ///Segundos de la ventana del limite general
  int get rateLimitWindowSeconds =>
      find<int>('RATE_LIMIT_WINDOW_SECONDS', required: false) ?? 60;

  ///Fallos de login seguidos que bloquean una IP
  int get loginMaxFailures =>
      find<int>('LOGIN_MAX_FAILURES', required: false) ?? 10;

  ///Segundos que dura el bloqueo de una IP tras [loginMaxFailures] fallos
  int get loginLockSeconds =>
      find<int>('LOGIN_LOCK_SECONDS', required: false) ?? 15 * 60;

  ///Milisegundos de espera antes de responder a un login fallido
  int get loginFailureDelayMs =>
      find<int>('LOGIN_FAILURE_DELAY_MS', required: false) ?? 1000;

  String get adminPrefix {
    final String key = 'ADMIN_PREFIX';
    final String defaultValue = '_admin';
    final raw = find<String>(key, required: false) ?? defaultValue;
    return _normalize(key, raw);
  }

  List<String> get reservedBucketNames {
    final String key = 'RESERVED_BUCKET_NAMES';
    final rawList = find<List<String>>(key, required: false) ?? [];
    return [...rawList.map((e) => _normalize(key, e)), adminPrefix];
  }

  String _normalize(String key, String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    if (sanitized != value) {
      stdout.writeln(
        '\n'
                'WARNING: Environment variable "$key" contained invalid characters. '
                'Normalized "$value" to "$sanitized"'
                '\n'
            .stylize(bold: true, color: ConsoleColor.yellow),
      );
    }
    return sanitized;
  }
}
