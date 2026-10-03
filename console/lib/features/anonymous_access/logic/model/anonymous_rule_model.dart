/// Operations a rule allows without credentials. The names are the ones the
/// API expects (`readOnly`, `writeOnly`, `readWrite`)
enum AnonymousAccessType { readOnly, writeOnly, readWrite }

/// Anonymous access rule: a prefix of the bucket, or a pattern with `*` as a
/// wildcard, reachable without credentials
class AnonymousRuleModel {
  final String prefix;
  final AnonymousAccessType access;

  AnonymousRuleModel({required this.prefix, required this.access});
}
