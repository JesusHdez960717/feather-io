import 'package:service/feather.dart';

/// The answers of the S3 API: XML by default, as S3, or JSON when the client
/// accepts it (the console). The model decides both forms: `toJson()` and
/// `toXml()`.
abstract final class S3Response {
  static bool acceptsJson(RequestEntity request) =>
      request.headers['accept']?.contains('application/json') == true;

  /// A 200 with [body]: its JSON when the client accepts it, its XML otherwise.
  static ResponseEntity ok(RequestEntity request, XmlSerializable body) =>
      acceptsJson(request) ? ResponseEntity.ok(body: body) : xml(body.toXml());

  /// [document] as an XML response.
  static ResponseEntity xml(
    XmlElement document, {
    int status = 200,
    Map<String, Object>? headers,
  }) => ResponseEntity(
    status,
    body: document.toXmlString(),
    headers: {...?headers, 'content-type': 'application/xml'},
  );
}
