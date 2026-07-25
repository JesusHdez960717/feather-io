import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'objects_subscreen.dart';

class ObjectsGridDatasource extends StatelessWidget {
  final BrowserSearchState state;
  final List<BrowserObjectWrapper> filteredWrappers;
  final TextEditingController searchController;
  final Function(String prefix) onNavigate;
  final Function(BrowserObjectModel) onSelected;

  const ObjectsGridDatasource({
    required this.state,
    required this.filteredWrappers,
    required this.searchController,
    required this.onNavigate,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredWrappers.isEmpty && state is BrowserSearchOkState) {
      return NoDataPage(
        title: searchController.text.isEmpty
            ? 'No objects found'
            : 'No objects matching "${searchController.text}"',
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(app.dimensions.padding.m),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: app.dimensions.padding.m,
        crossAxisSpacing: app.dimensions.padding.m,
        childAspectRatio: 0.9,
      ),
      itemCount: filteredWrappers.length,
      itemBuilder: (context, index) {
        final wrapper = filteredWrappers[index];
        return InkWell(
          onTap: () {
            if (wrapper.isFolder) {
              onNavigate(wrapper.fullPath);
            } else {
              final obj = state.objects!.objects.firstWhere(
                (o) => o.key == wrapper.fullPath,
              );
              onSelected(obj);
            }
          },
          borderRadius: app.dimensions.border.borderRadius.m,
          child: Container(
            decoration: BoxDecoration(
              color: app.colors.primary.background3,
              borderRadius: app.dimensions.border.borderRadius.m,
              border: Border.all(color: app.colors.neutral.grey5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  wrapper.isFolder ? Icons.folder : Icons.insert_drive_file,
                  size: 40,
                  color: wrapper.isFolder ? Colors.amber : Colors.blue,
                ),
                app.dimensions.padding.s.gap(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    wrapper.name,
                    style: app.textTheme.bodyMedium?.copyWith(
                      color: app.colors.neutral.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
