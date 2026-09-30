import 'package:service/feather.dart';

/// Reemplaza los metadatos del bucket: un campo a null lo borra.
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

    //color ARGB de 32 bits sin signo, como lo envia la consola (Color.toARGB32)
    cvc.buildValidator('color').min(0).max(0xFFFFFFFF).validate(color);

    return cvc;
  }

  @override
  Object? toJson() {
    return {'description': description, 'color': color};
  }
}
