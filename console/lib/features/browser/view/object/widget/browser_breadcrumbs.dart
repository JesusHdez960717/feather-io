import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class BrowserBreadcrumbs extends StatelessWidget {
  final String bucketName;
  final String prefix;
  final Function(String prefix) onNavigate;
  final ScrollController scrollController;

  const BrowserBreadcrumbs({
    required this.bucketName,
    required this.prefix,
    required this.onNavigate,
    required this.scrollController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final parts = prefix.split('/').where((s) => s.isNotEmpty).toList();

    List<Widget> children = [];

    // Bucket name (root of object navigation)
    children.add(
      _breadcrumbItem(
        label: bucketName,
        onTap: parts.isEmpty ? null : () => onNavigate(''),
        isLast: parts.isEmpty,
        icon: app.assets.icons.storage.bucket.build(
          color: app.colors.neutral.white,
          size: 14,
        ),
      ),
    );

    String cumulativePath = '';
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      cumulativePath += '$part/';
      final isLast = i == parts.length - 1;
      final targetPath = cumulativePath;

      children.add(_separator());
      children.add(
        _breadcrumbItem(
          label: part,
          onTap: isLast ? null : () => onNavigate(targetPath),
          isLast: isLast,
        ),
      );
    }

    return Expanded(
      child: Container(
        height: 38,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: app.colors.primary.background3,
          borderRadius: app.dimensions.border.borderRadius.xs,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.5),
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(children: children),
          ),
        ),
      ),
    );
  }

  Widget _separator() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: app.assets.icons.navigation.next.build(
      size: 16,
      color: app.colors.neutral.grey3,
    ),
  );

  Widget _breadcrumbItem({
    required VoidCallback? onTap,
    required bool isLast,
    required String label,
    Widget? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: app.dimensions.border.borderRadius.xs,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              ?icon,
              if (icon != null && label.isNotEmpty)
                app.dimensions.padding.s.gap(),
              Text(
                label,
                style: app.textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: app.colors.neutral.white,
                  fontWeight: isLast ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
