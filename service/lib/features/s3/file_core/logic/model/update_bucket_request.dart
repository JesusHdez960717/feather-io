import 'package:service/feather.dart';

/// Replaces the bucket metadata: a null field clears it.
class UpdateBucketRequest implements Serializable, Validatable {
  final String? description;
  final int? color;

  UpdateBucketRequest({this.description, this.color});

  factory UpdateBucketRequest.fromJson(Map<String, dynamic> json) {
    return UpdateBucketRequest(
      description: json['description'] as String?,
      color: json['color'] as int?,
    );
  }

  @override
  ConstraintValidatorContext validate() {
    final cvc = ConstraintValidatorContext();

    cvc
        .buildValidator('description')
        .size(max: CreateBucketRequest.maxDescriptionLength)
        .validate(description);

    // Unsigned 32-bit ARGB color, as the console sends it (Color.toARGB32)
    cvc.buildValidator('color').min(0).max(0xFFFFFFFF).validate(color);

    return cvc;
  }

  @override
  Object? toJson() {
    return {'description': description, 'color': color};
  }
}
