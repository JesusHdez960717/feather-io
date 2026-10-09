import 'package:service/feather.dart';

class CreateBucketRequest implements Validatable {
  static const int maxDescriptionLength = 1024;

  final String? description;
  final int? color;

  CreateBucketRequest({this.description, this.color});

  /// The example of the OpenAPI document.
  static final CreateBucketRequest example = CreateBucketRequest(
    description: 'Photos of the 2026 trip',
    color: 0xFF2196F3,
  );

  factory CreateBucketRequest.fromJson(Map<String, dynamic> json) {
    return CreateBucketRequest(
      description: json.field<String?>('description'),
      color: json.field<int?>('color'),
    );
  }

  @override
  ConstraintValidatorContext validate() => ConstraintValidatorContext()
    ..field('description', description).size(max: maxDescriptionLength)
    // Unsigned 32-bit ARGB color, as the console sends it (Color.toARGB32)
    ..field('color', color).min(0).max(0xFFFFFFFF);

  Map<String, Object?> toJson() {
    return {'description': description, 'color': color};
  }
}
