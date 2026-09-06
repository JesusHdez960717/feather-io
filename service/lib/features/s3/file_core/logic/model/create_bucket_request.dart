import 'package:service/feather.dart';

class CreateBucketRequest implements Serializable {
  final String? description;
  final int? color;

  CreateBucketRequest({
    this.description,
    this.color,
  });

  factory CreateBucketRequest.fromJson(Map<String, dynamic> json) {
    return CreateBucketRequest(
      description: json['description'] as String?,
      color: json['color'] as int?,
    );
  }

  @override
  Object? toJson() {
    return {
      'description': description,
      'color': color,
    };
  }
}
