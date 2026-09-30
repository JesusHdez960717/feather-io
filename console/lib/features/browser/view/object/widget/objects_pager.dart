import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///Pie de la lista de objetos: a la izquierda, que la busqueda y los filtros
///solo miran las paginas ya cargadas; a la derecha, filas por pagina y
///*‹ Pagina X de N ›*
class ObjectsPager extends StatelessWidget {
  final BrowserSearchState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onPageSizeChanged;

  const ObjectsPager({
    required this.state,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSizeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final busy = state is! BrowserLoadingSuccessState;
    final totalPages = state.totalPages;
    return Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.l),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
          right: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
          top: BorderSide(color: app.colors.neutral.grey5),
          bottom: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: app.colors.neutral.grey3),
          app.dimensions.padding.s.gap(),
          Expanded(
            child: Text(
              totalPages > 1
                  ? app.intl.objectsPagerHintPages(
                      state.pages.length,
                      totalPages,
                    )
                  : app.intl.objectsPagerHint,
              overflow: TextOverflow.ellipsis,
              style: app.textTheme.bodySmall?.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
          ),
          app.dimensions.padding.xl.gap(),
          Text(
            app.intl.objectsPageSize,
            style: app.textTheme.bodyMedium?.copyWith(
              color: app.colors.neutral.grey2,
            ),
          ),
          app.dimensions.padding.m.gap(),
          DropdownButton<int>(
            value: state.pageSize,
            isDense: true,
            dropdownColor: app.colors.primary.background2,
            style: app.textTheme.bodyMedium,
            onChanged: busy
                ? null
                : (size) {
                    if (size != null) onPageSizeChanged(size);
                  },
            items: [
              for (final size in BrowserPagination.pageSizes)
                DropdownMenuItem(value: size, child: Text('$size')),
            ],
          ),
          (2 * app.dimensions.padding.l).gap(),
          IconButton(
            tooltip: app.intl.objectsPreviousPage,
            onPressed: !busy && state.canGoPrevious ? onPrevious : null,
            icon: app.assets.icons.navigation.left.build(
              size: 18,
              color: !busy && state.canGoPrevious
                  ? app.colors.neutral.grey2
                  : app.colors.neutral.grey5,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              app.intl.objectsPageOf(state.pageIndex + 1, totalPages),
              textAlign: TextAlign.center,
              style: app.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            tooltip: app.intl.objectsNextPage,
            onPressed: !busy && state.canGoNext ? onNext : null,
            icon: app.assets.icons.navigation.right.build(
              size: 18,
              color: !busy && state.canGoNext
                  ? app.colors.neutral.grey2
                  : app.colors.neutral.grey5,
            ),
          ),
        ],
      ),
    );
  }
}
