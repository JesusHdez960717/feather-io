enum AnonymousAccessType { readOnly, writeOnly, readWrite }

class AnonymousRuleModel {
  final String prefix;
  final AnonymousAccessType access;

  AnonymousRuleModel(this.prefix, this.access);
}
