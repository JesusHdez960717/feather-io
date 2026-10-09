import 'package:service/feather.dart';

/// Replaces the bucket metadata: a null field clears it.
class UpdateBucketRequest implements Validatable {
  final String? description;
  final int? color;

  UpdateBucketRequest({this.description, this.color});

  /// The example of the OpenAPI document.
  static final UpdateBucketRequest example = UpdateBucketRequest(
    description: 'Photos of the 2026 trip',
    color: 0xFF2196F3,
  );

  factory UpdateBucketRequest.fromJson(Map<String, dynamic> json) {
    return UpdateBucketRequest(
      description: json.field<String?>('description'),
      color: json.field<int?>('color'),
    );
  }

  @override
  ConstraintValidatorContext validate() => ConstraintValidatorContext()
    ..field(
      'description',
      description,
    ).size(max: CreateBucketRequest.maxDescriptionLength)
    // Unsigned 32-bit ARGB color, as the console sends it (Color.toARGB32)
    ..field('color', color).min(0).max(0xFFFFFFFF);

  Map<String, Object?> toJson() {
    return {'description': description, 'color': color};
  }
}
