import 'dart:io';

import 'package:service/feather.dart';

/// Default maximum object size (5 GiB, the limit of a single `PUT` in S3).
const int defaultMaxObjectSize = 5 * 1024 * 1024 * 1024;

extension ExtendedEnv on Env {
  String get secret => find<String>('FEATHER_SECRET', required: true)!;

  String get access => find<String>('FEATHER_ACCESS', required: true)!;

  String get jwtSecret => find<String>('JWT_SECRET', required: true)!;

  String get storageVolumePath =>
      find<String>('STORAGE_VOLUME_PATH', required: true)!;

  /// Maximum size (in bytes) of an object uploaded with `PUT`.
  int get maxObjectSize =>
      find<int>('MAX_OBJECT_SIZE', required: false) ?? defaultMaxObjectSize;

  /// Public URL of the service (`https://s3.example.com`), for presigned URLs.
  /// Without it the request's scheme and `Host` are used, which behind an HTTPS
  /// proxy would give `http://`. Scheme, host and port only: the path is part of
  /// the signature.
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
        'must be scheme, host and port, without a path (https://s3.example.com)',
      );
    }
    return uri;
  }

  /// Proxies of your own in front of the service that add their entry to
  /// `X-Forwarded-For`; with 0 (the default) the connection's IP is used.
  int get trustedProxies => find<int>('TRUSTED_PROXIES', required: false) ?? 0;

  /// Requests per IP in each [rateLimitWindowSeconds] window (general limit);
  /// 0 disables it. High by default: S3 clients send bursts (parallel uploads,
  /// `sync` of many files).
  int get rateLimitRequests =>
      find<int>('RATE_LIMIT_REQUESTS', required: false) ?? 2000;

  /// Seconds of the general limit's window.
  int get rateLimitWindowSeconds =>
      find<int>('RATE_LIMIT_WINDOW_SECONDS', required: false) ?? 60;

  /// Failed logins in a row that lock an IP.
  int get loginMaxFailures =>
      find<int>('LOGIN_MAX_FAILURES', required: false) ?? 10;

  /// Seconds an IP stays locked after [loginMaxFailures] failures.
  int get loginLockSeconds =>
      find<int>('LOGIN_LOCK_SECONDS', required: false) ?? 15 * 60;

  /// Milliseconds to wait before answering a failed login.
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
