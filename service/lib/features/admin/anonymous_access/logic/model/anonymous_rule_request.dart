import 'package:service/feather.dart';

class CreateRuleRequest implements Validatable {
  final String? prefix;
  final String? access;

  CreateRuleRequest(this.prefix, this.access);

  /// The example of the OpenAPI document.
  static final CreateRuleRequest example = CreateRuleRequest(
    'public/',
    AnonymousAccessType.readOnly.name,
  );

  factory CreateRuleRequest.fromJson(Map<String, dynamic> json) {
    return CreateRuleRequest(
      json.field<String?>('prefix'),
      json.field<String?>('access'),
    );
  }

  @override
  ConstraintValidatorContext validate() => ConstraintValidatorContext()
    ..field('prefix', prefix).notNull().size(min: 1, max: 128)
    ..field('access', access).notNull().isEnum(AnonymousAccessType.values);

  AnonymousRuleModel toModel() {
    return AnonymousRuleModel(
      prefix!,
      AnonymousAccessType.values.byName(access!),
    );
  }

  Map<String, Object?> toJson() => {'prefix': prefix, 'access': access};
}

class DeleteRuleRequest implements Validatable {
  final String? prefix;

  DeleteRuleRequest(this.prefix);

  /// The example of the OpenAPI document.
  static final DeleteRuleRequest example = DeleteRuleRequest('public/');

  factory DeleteRuleRequest.fromJson(Map<String, dynamic> json) {
    return DeleteRuleRequest(json.field<String?>('prefix'));
  }

  @override
  ConstraintValidatorContext validate() =>
      ConstraintValidatorContext()
        ..field('prefix', prefix).notNull().size(min: 1, max: 128);

  Map<String, Object?> toJson() => {'prefix': prefix};
}
