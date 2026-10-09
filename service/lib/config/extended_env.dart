import 'package:service/feather.dart';

/// Default maximum object size (5 GiB, the limit of a single `PUT` in S3).
const int defaultMaxObjectSize = 5 * 1024 * 1024 * 1024;

/// The variables the service can't start without.
const List<String> requiredEnvVariables = [
  'FEATHER_ACCESS',
  'FEATHER_SECRET',
  'JWT_SECRET',
  'KEYS_ENCRYPTION_SECRET',
  'STORAGE_VOLUME_PATH',
];

extension ExtendedEnv on Env {
  String get secret => require<String>('FEATHER_SECRET');

  String get access => require<String>('FEATHER_ACCESS');

  String get jwtSecret => require<String>('JWT_SECRET');

  /// Encrypts the secrets of the access keys in the database (see
  /// [SecretCipher]). Changing it makes every stored secret unreadable.
  String get keysEncryptionSecret => require<String>('KEYS_ENCRYPTION_SECRET');

  String get storageVolumePath => require<String>('STORAGE_VOLUME_PATH');

  /// Maximum size (in bytes) of an object uploaded with `PUT`.
  int get maxObjectSize => find<int>('MAX_OBJECT_SIZE') ?? defaultMaxObjectSize;

  /// Public URL of the service (`https://s3.example.com`), for presigned URLs.
  /// Without it the request's scheme and `Host` are used, which behind an HTTPS
  /// proxy would give `http://`. Scheme, host and port only: the path is part of
  /// the signature.
  Uri? get publicUrl {
    final raw = find<String>('PUBLIC_URL');
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
        'must be scheme, host and port, without a path (https://s3.example.com)',
      );
    }
    return uri;
  }

  /// Proxies of your own in front of the service that add their entry to
  /// `X-Forwarded-For`; with 0 (the default) the connection's IP is used.
  int get trustedProxies => find<int>('TRUSTED_PROXIES') ?? 0;

  /// Requests per IP in each [rateLimitWindowSeconds] window (general limit);
  /// 0 disables it. High by default: S3 clients send bursts (parallel uploads,
  /// `sync` of many files).
  int get rateLimitRequests => find<int>('RATE_LIMIT_REQUESTS') ?? 2000;

  /// Seconds of the general limit's window.
  int get rateLimitWindowSeconds =>
      find<int>('RATE_LIMIT_WINDOW_SECONDS') ?? 60;

  /// Failed logins in a row that lock an IP.
  int get loginMaxFailures => find<int>('LOGIN_MAX_FAILURES') ?? 10;

  /// Seconds an IP stays locked after [loginMaxFailures] failures.
  int get loginLockSeconds => find<int>('LOGIN_LOCK_SECONDS') ?? 15 * 60;

  /// Milliseconds to wait before answering a failed login.
  int get loginFailureDelayMs => find<int>('LOGIN_FAILURE_DELAY_MS') ?? 1000;

  String get adminPrefix {
    final String key = 'ADMIN_PREFIX';
    final String defaultValue = '_admin';
    final raw = find<String>(key) ?? defaultValue;
    return _normalize(key, raw);
  }

  List<String> get reservedBucketNames {
    final String key = 'RESERVED_BUCKET_NAMES';
    final rawList = find<List<String>>(key) ?? [];
    return [...rawList.map((e) => _normalize(key, e)), adminPrefix];
  }

  /// The logger of the service: `LOG_FORMAT=json` writes one JSON object per
  /// line (for a log collector), anything else readable lines; `LOG_LEVEL`
  /// (`debug`, `info`, `warning`, `error`) is `info` by default.
  WinterLogger get serviceLogger {
    final level = findEnum('LOG_LEVEL', LogLevel.values) ?? LogLevel.info;
    return find<String>('LOG_FORMAT') == 'json'
        ? JsonLogger(minLevel: level)
        : ConsoleLogger(minLevel: level);
  }

  String _normalize(String key, String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    if (sanitized != value) {
      logger.warning(
        'The environment variable $key had invalid characters: it is used without them',
        fields: {'variable': key, 'value': sanitized},
      );
    }
    return sanitized;
  }
}
