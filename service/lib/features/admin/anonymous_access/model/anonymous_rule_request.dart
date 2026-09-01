import 'package:service/feather.dart';

class CreateRuleRequest implements Validatable {
  final String? prefix;
  final String? access;

  CreateRuleRequest(this.prefix, this.access);

  factory CreateRuleRequest.fromJson(Map<String, dynamic> json) {
    return CreateRuleRequest(
      json['prefix'] as String?,
      json['access'] as String?,
    );
  }

  @override
  ConstraintValidatorContext validate() {
    final cvc = ConstraintValidatorContext();

    cvc
        .buildValidator('prefix')
        .notNull()
        .size(min: 1, max: 128)
        .validate(prefix);

    cvc
        .buildValidator('access')
        .notNull()
        .isEnum(AnonymousAccessType.values)
        .validate(access);

    return cvc;
  }

  AnonymousRuleModel toModel() {
    return AnonymousRuleModel(
      prefix!,
      AnonymousAccessType.values.byName(access!),
    );
  }
}

class DeleteRuleRequest implements Validatable {
  final String? prefix;

  DeleteRuleRequest(this.prefix);

  factory DeleteRuleRequest.fromJson(Map<String, dynamic> json) {
    return DeleteRuleRequest(json['prefix'] as String?);
  }

  @override
  ConstraintValidatorContext validate() {
    final cvc = ConstraintValidatorContext();

    cvc
        .buildValidator('prefix')
        .notNull()
        .size(min: 1, max: 128)
        .validate(prefix);

    return cvc;
  }
}
