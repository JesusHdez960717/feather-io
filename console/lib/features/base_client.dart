import 'package:dio/dio.dart';

enum AcceptedTypes {
  json('application/json'),
  xml('application/xml');

  final String contentType;

  const AcceptedTypes(this.contentType);
}

abstract class BaseClient {
  String get baseUrl;

  final Dio dio;

  BaseClient(this.dio);

  Options options({
    String? token,
    AcceptedTypes? accept,
  }) {
    return Options(
      headers: <String, dynamic>{
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': (accept ?? AcceptedTypes.json).contentType,
      },
    );
  }
}
