import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///Lista de objetos vacia: sin objetos, sin coincidencias de la busqueda o del filtro
class ObjectsEmptyPage extends StatelessWidget {
  final String query;
  final bool hasActiveFilter;

  const ObjectsEmptyPage({
    required this.query,
    required this.hasActiveFilter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isNotEmpty) {
      return NoDataPage(title: app.intl.objectsNoMatch(query));
    }
    if (hasActiveFilter) {
      return NoDataPage(title: app.intl.objectsNoMatchFilter);
    }
    return NoDataPage(
      title: app.intl.objectsEmpty,
      description: app.intl.objectsDragHint,
    );
  }
}
