import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class BucketClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  BucketClient(super.dio);

  Future<List<BucketResponse>> listBuckets({String? token}) async {
    Response rawResponse = await dio.get(
      baseUrl,
      options: options(token: token),
    );

    return (rawResponse.data as List)
        .map((e) => BucketResponse.fromJson(e))
        .toList();
  }

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

  Future<BucketResponse> updateBucket({
    required String name,
    required BucketUpdateRequest request,
    String? token,
  }) async {
    final admin = Environment.adminPrefix;
    Response rawResponse = await dio.put(
      '$baseUrl/$admin/bucket/$name',
      data: request.toJson(),
      options: options(token: token),
    );

    return BucketResponse.fromJson(rawResponse.data);
  }

  /// Deletes every object of the bucket; the bucket and its settings stay
  Future<void> emptyBucket({required String name, String? token}) async {
    final admin = Environment.adminPrefix;
    await dio.delete(
      '$baseUrl/$admin/bucket/$name/objects',
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

//---------- BUCKET UPDATE REQUEST ----------
/// Replaces the metadata: a field set to null is deleted on the service
class BucketUpdateRequest {
  final String? description;
  final int? color;

  BucketUpdateRequest({this.description, this.color});

  Map<String, dynamic> toJson() {
    return {'description': description, 'color': color};
  }
}

//---------- BUCKET RESPONSE ----------
class BucketResponse {
  final String name;
  final int objectCount;
  final int sizeBytes;
  final DateTime creationDate;
  final DateTime? lastModified;

  final String? description;
  final int? color;

  BucketResponse({
    required this.name,
    required this.objectCount,
    required this.sizeBytes,
    required this.creationDate,
    this.lastModified,
    this.description,
    this.color,
  });

  factory BucketResponse.fromJson(Map<String, dynamic> json) {
    return BucketResponse(
      name: json['name'],
      description: json['description'],
      color: json['color'],
      objectCount: json['object_count'],
      sizeBytes: json['size_bytes'],
      creationDate: DateTime.parse(json['creation_date']).toLocal(),
      lastModified: json['last_modified'] == null
          ? null
          : DateTime.parse(json['last_modified']).toLocal(),
    );
  }
}
