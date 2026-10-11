import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

enum ViewType {
  list,
  grid;

  static ViewType? fromName(String? name) {
    if (name == null) return null;
    return ViewType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ViewType.list,
    );
  }
}

class ViewTypeSelector extends StatelessWidget {
  final ViewType currentType;
  final Function(ViewType) onChanged;

  const ViewTypeSelector({
    required this.currentType,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: EdgeInsets.all(app.dimensions.padding.xs),
      decoration: BoxDecoration(
        color: app.colors.primary.background3,
        borderRadius: app.dimensions.border.borderRadius.m,
        border: Border.all(color: app.colors.neutral.grey5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewTypeButton(
            icon: app.assets.icons.viewType.list,
            isSelected: currentType == ViewType.list,
            onPressed: () => onChanged(ViewType.list),
          ),
          app.dimensions.padding.xs.gap(),
          _ViewTypeButton(
            icon: app.assets.icons.viewType.grid,
            isSelected: currentType == ViewType.grid,
            onPressed: () => onChanged(ViewType.grid),
          ),
        ],
      ),
    );
  }
}

class _ViewTypeButton extends StatelessWidget {
  final SvgAsset icon;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ViewTypeButton({
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppFocusRing(
      child: InkWell(
        onTap: onPressed,
        borderRadius: app.dimensions.border.borderRadius.s,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected ? app.colors.primary.purple : Colors.transparent,
            borderRadius: app.dimensions.border.borderRadius.s,
          ),
          alignment: Alignment.center,
          child: icon.build(
            size: 18,
            color: isSelected
                ? app.colors.neutral.white
                : app.colors.neutral.grey3,
          ),
        ),
      ),
    );
  }
}
