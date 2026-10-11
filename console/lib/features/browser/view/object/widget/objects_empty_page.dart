import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// Empty object list: no objects, or nothing matches the search or the filter
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
