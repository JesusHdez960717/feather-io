import 'package:service/feather.dart';

class DeleteObjectsResponse implements XmlSerializable {
  final List<String> deleted;
  final List<DeleteError> errors;
  final bool quiet;

  DeleteObjectsResponse({
    required this.deleted,
    required this.errors,
    this.quiet = false,
  });

  Map<String, Object?> toJson() {
    return {
      if (!quiet) 'deleted': deleted.map((key) => {'key': key}).toList(),
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }

  /// DeleteResult: the deleted keys (none in quiet mode) and the errors.
  @override
  XmlElement toXml() => S3Xml.root('DeleteResult', [
    if (!quiet)
      for (final key in deleted)
        XmlElement('Deleted', elements: [XmlElement.leaf('Key', key)]),
    for (final error in errors)
      XmlElement(
        'Error',
        elements: [
          XmlElement.leaf('Key', error.key),
          XmlElement.leaf('Code', error.code),
          XmlElement.leaf('Message', error.message),
        ],
      ),
  ]);
}

class DeleteError {
  final String key;
  final String code;
  final String message;

  DeleteError({required this.key, required this.code, required this.message});

  Map<String, Object?> toJson() {
    return {'key': key, 'code': code, 'message': message};
  }
}
