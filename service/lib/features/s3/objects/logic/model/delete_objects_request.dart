import 'package:service/feather.dart';

class DeleteObjectsRequest {
  final List<String> keys;
  final bool quiet;

  DeleteObjectsRequest({required this.keys, this.quiet = false});

  /// The S3 body:
  /// `<Delete><Quiet>true</Quiet><Object><Key>k</Key></Object>…</Delete>`.
  /// Another root is a [FormatException].
  factory DeleteObjectsRequest.fromXml(XmlElement delete) {
    if (delete.name != 'Delete') {
      throw FormatException('<Delete> was expected, not <${delete.name}>');
    }
    return DeleteObjectsRequest(
      keys: [
        for (final object in delete.children('Object'))
          if (object.childText('Key') case final key? when key.isNotEmpty) key,
      ],
      quiet: delete.childText('Quiet')?.trim().toLowerCase() == 'true',
    );
  }

  /// The console's JSON: `{"objects": [{"key": "a.txt"}], "quiet": false}`.
  factory DeleteObjectsRequest.fromJson(Map<String, dynamic> json) {
    return DeleteObjectsRequest(
      keys: [
        for (final object in json.field<List<DeleteObjectEntry>>('objects'))
          if (object.key.isNotEmpty) object.key,
      ],
      quiet: json.field<bool?>('quiet') ?? false,
    );
  }
}

/// One object of the JSON body of [DeleteObjectsRequest].
class DeleteObjectEntry {
  final String key;

  DeleteObjectEntry({required this.key});

  factory DeleteObjectEntry.fromJson(Map<String, dynamic> json) {
    return DeleteObjectEntry(key: json.field<String>('key'));
  }
}
