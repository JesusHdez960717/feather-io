import 'package:service/feather.dart';

class CreateBucketRequest implements Serializable, Validatable {
  static const int maxDescriptionLength = 1024;

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
  ConstraintValidatorContext validate() {
    final cvc = ConstraintValidatorContext();

    cvc
        .buildValidator('description')
        .size(max: maxDescriptionLength)
        .validate(description);

    // Unsigned 32-bit ARGB color, as the console sends it (Color.toARGB32)
    cvc
        .buildValidator('color')
        .min(0)
        .max(0xFFFFFFFF)
        .validate(color);

    return cvc;
  }

  @override
  Object? toJson() {
    return {
      'description': description,
      'color': color,
    };
  }
}
