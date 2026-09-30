import 'package:service/feather.dart';

/// Serializa las [S3Exception] como el `<Error>` de S3: XML por defecto y
/// JSON si el cliente lo pide con `Accept` o si es la API de admin.
/// El resto de excepciones siguen el comportamiento de Winter.
class S3ExceptionHandler extends SimpleExceptionHandler {
  final String adminPrefix = env.adminPrefix;

  @override
  Future<ResponseEntity> call(
    RequestEntity request,
    Exception exception,
    StackTrace stackTrace,
  ) async {
    if (exception is! S3Exception) {
      return super.call(request, exception, stackTrace);
    }

    if (_isAdmin(request) || _acceptsJson(request)) {
      return ResponseEntity(exception.statusCode, body: exception);
    }
    return ResponseEntity(
      exception.statusCode,
      body: _mapExceptionToXml(exception),
      headers: {'content-type': 'application/xml'},
    );
  }

  bool _isAdmin(RequestEntity request) {
    final segments = request.requestedUri.pathSegments;
    return segments.isNotEmpty && segments.first == adminPrefix;
  }

  bool _acceptsJson(RequestEntity request) =>
      request.headers['accept']?.contains('application/json') == true;

  String _mapExceptionToXml(S3Exception exception) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<Error>');
    buffer.writeln('  <Code>${exception.code.code}</Code>');
    buffer.writeln('  <Message>${_escapeXml(exception.message)}</Message>');
    if (exception.resource != null) {
      buffer.writeln('  <Resource>${_escapeXml(exception.resource!)}</Resource>');
    }
    buffer.writeln('</Error>');
    return buffer.toString();
  }

  String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
