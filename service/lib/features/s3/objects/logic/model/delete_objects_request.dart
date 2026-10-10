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

  factory DeleteObjectsRequest.fromJson(Map<String, dynamic> json) {
    // Accepts the standard shape ({"Delete": {"Object": [...]}}) and the
    // console's lowercase one ({"delete": {"objects": [...]}})
    final delete = json['Delete'] ?? json['delete'] ?? json;

    final List<dynamic> objectsList = (delete is Map)
        ? (delete['Object'] ?? delete['object'] ?? delete['objects'] ?? [])
        : [];

    final keys = objectsList
        .map((e) {
          if (e is String) return e;
          if (e is Map) return (e['Key'] ?? e['key'] ?? '').toString();
          return '';
        })
        .where((k) => k.isNotEmpty)
        .toList();

    final quietValue = (delete is Map)
        ? (delete['Quiet'] ?? delete['quiet'])
        : false;

    return DeleteObjectsRequest(
      keys: keys,
      quiet: quietValue == true || quietValue == 'true',
    );
  }
}
