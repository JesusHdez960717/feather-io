import 'package:console/app_exporter.dart';

class BucketClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  BucketClient(super.dio);

  Future<void> createBucket({
    required String name,
    required BucketCreateRequest request,
    String? token,
  }) async {
    await dio.put(
      '$baseUrl/$name',
      data: request.toJson(),
      options: options(token: token),
    );
  }

  Future<void> deleteBucket({required String name, String? token}) async {
    await dio.delete('$baseUrl/$name', options: options(token: token));
  }
}

//---------- BUCKET CREATE REQUEST ----------
class BucketCreateRequest {
  final String? description;
  final int? color;

  BucketCreateRequest({this.description, this.color});

  Map<String, dynamic> toJson() {
    return {
      if (description != null) 'description': description,
      if (color != null) 'color': color,
    };
  }
}
