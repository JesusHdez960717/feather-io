import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// A column of [AppSimpleTable]
class AppTableColumn {
  /// Header text; empty for an actions column
  final String title;

  /// Fixed width; null takes the remaining space
  final double? width;

  /// Without padding and centered, for an icon button or a menu
  final bool compact;

  const AppTableColumn(this.title, {this.width, this.compact = false});

  const AppTableColumn.actions({double width = 56})
    : this('', width: width, compact: true);
}

/// A row of [AppSimpleTable]: one widget per column
class AppTableRow {
  final List<Widget> cells;

  /// Rows grow beyond it when a cell needs more (two lines, chips that wrap)
  final double minHeight;

  const AppTableRow(this.cells, {this.minHeight = 52});
}

/// Bordered table for short lists with rich cells (several lines, chips,
/// badges): the anonymous rules and the access keys. Long lists with
/// selection or paging use `SfDataGrid` (buckets, objects)
class AppSimpleTable extends StatelessWidget {
  static const double headerHeight = 42;

  /// Inside the border, above the column titles: search, filters…
  final Widget? toolbar;

  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;

  /// Shown after the rows, e.g. an empty state or "no results"
  final Widget? placeholder;

  /// Info line at the bottom of the table
  final String? hint;

  const AppSimpleTable({
    required this.columns,
    required this.rows,
    this.toolbar,
    this.placeholder,
    this.hint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final divider = BorderSide(
      color: app.colors.neutral.white.withValues(alpha: 0.08),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.m,
        border: Border.all(color: app.colors.neutral.grey5),
      ),
      child: Column(
        children: [
          if (toolbar != null)
            Container(
              padding: EdgeInsets.all(app.dimensions.padding.l),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: app.colors.neutral.grey5),
                ),
              ),
              child: toolbar,
            ),
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: app.colors.neutral.white.withValues(alpha: 0.16),
                ),
              ),
            ),
            child: _buildRow([
              for (final column in columns)
                Text(
                  column.title,
                  style: app.textTheme.bodyMedium?.copyWith(
                    color: app.colors.neutral.grey3,
                  ),
                ),
            ]),
          ),
          for (final row in rows)
            Container(
              constraints: BoxConstraints(minHeight: row.minHeight),
              padding: EdgeInsets.symmetric(
                vertical: app.dimensions.padding.xs,
              ),
              decoration: BoxDecoration(border: Border(bottom: divider)),
              child: _buildRow(row.cells),
            ),
          ?placeholder,
          if (hint != null) _buildHint(hint!),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> cells) {
    return Row(
      children: [
        for (final (index, column) in columns.indexed)
          column.width == null
              ? Expanded(child: _cell(column, cells[index]))
              : _cell(column, cells[index]),
      ],
    );
  }

  Widget _cell(AppTableColumn column, Widget child) {
    if (column.compact) {
      return SizedBox(
        width: column.width,
        child: Center(child: child),
      );
    }
    return SizedBox(
      width: column.width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.l),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }

  Widget _buildHint(String text) {
    return Padding(
      padding: EdgeInsets.all(app.dimensions.padding.l),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: app.colors.neutral.grey3),
          app.dimensions.padding.s.gap(),
          Expanded(
            child: Text(
              text,
              style: app.textTheme.bodySmall?.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
