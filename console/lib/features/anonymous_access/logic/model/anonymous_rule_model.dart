///Operaciones que una regla permite sin credenciales. Los nombres son los que
///espera la API (`readOnly`, `writeOnly`, `readWrite`)
enum AnonymousAccessType { readOnly, writeOnly, readWrite }

///Regla de acceso anonimo: un prefijo del bucket (con `*` como comodin)
///accesible sin credenciales
class AnonymousRuleModel {
  final String prefix;
  final AnonymousAccessType access;

  AnonymousRuleModel({required this.prefix, required this.access});
}
