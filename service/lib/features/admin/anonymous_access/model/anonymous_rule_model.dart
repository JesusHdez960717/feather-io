import 'package:winter/winter.dart';

enum AnonymousAccessType { readOnly, writeOnly, readWrite }

class AnonymousRuleModel implements Serializable {
  final String prefix;
  final AnonymousAccessType access;

  AnonymousRuleModel(this.prefix, this.access);

  @override
  Object? toJson() {
    return {'prefix': prefix, 'access': access.name};
  }
}
