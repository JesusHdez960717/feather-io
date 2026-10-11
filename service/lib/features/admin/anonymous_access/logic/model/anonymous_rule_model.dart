enum AnonymousAccessType { readOnly, writeOnly, readWrite }

class AnonymousRuleModel {
  final String prefix;
  final AnonymousAccessType access;

  AnonymousRuleModel(this.prefix, this.access);

  /// The example of the OpenAPI document.
  static final AnonymousRuleModel example = AnonymousRuleModel(
    'public/',
    AnonymousAccessType.readOnly,
  );

  Map<String, Object?> toJson() {
    return {'prefix': prefix, 'access': access.name};
  }
}
