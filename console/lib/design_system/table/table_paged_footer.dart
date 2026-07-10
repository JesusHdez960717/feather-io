import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class TablePagedFooter extends StatelessWidget {
  final int currentPageSize;
  final List<int> pageSizes;
  final void Function(int newPageSize) onPageSizeChanged;
  final void Function(int newPage) onPageChanged;
  final int currentPage;
  final int totalPages;
  final double? height;

  const TablePagedFooter({
    required this.currentPageSize,
    required this.pageSizes,
    required this.onPageSizeChanged,
    required this.onPageChanged,
    required this.currentPage,
    required this.totalPages,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 56,
      padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.l),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        mainAxisAlignment: .end,
        crossAxisAlignment: .center,
        children: [
          Text(app.intl.rowsPerPage, style: app.textTheme.bodyMedium),
          app.dimensions.padding.s.gap(),
          DropdownButton<int>(
            value: currentPageSize,
            items: pageSizes
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text(
                      size.toString(),
                      style: app.textTheme.titleSmall,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              onPageSizeChanged(value);
            },
          ),
          app.dimensions.padding.l.gap(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0
                ? () {
                    onPageChanged(currentPage - 1);
                  }
                : null,
          ),
          Text(
            app.intl.pageXofY(currentPage + 1, totalPages),
            style: app.textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () {
                    onPageChanged(currentPage + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
