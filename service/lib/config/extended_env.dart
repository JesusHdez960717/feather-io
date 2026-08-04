import 'dart:io';

import 'package:service/feather.dart';

extension ExtendedEnv on Env {
  String get secret => find<String>('FEATHER_SECRET', required: true)!;

  String get access => find<String>('FEATHER_ACCESS', required: true)!;

  String get storageVolumePath =>
      find<String>('STORAGE_VOLUME_PATH', required: true)!;

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
