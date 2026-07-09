import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? errorText;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;

  const AppDropdown({
    required this.items,
    this.value,
    this.onChanged,
    this.label,
    this.errorText,
    this.height,
    this.borderRadius,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FormComponentTemplate(
      label: label,
      errorText: errorText,
      height: height ?? 50,
      borderRadius: borderRadius,
      borderColor: borderColor,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        dropdownColor: app.colors.primary.backgroundForm,
        iconEnabledColor: app.colors.neutral.white,
        style: app.textTheme.bodyLarge?.copyWith(
          color: app.colors.neutral.white,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: app.dimensions.padding.m,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
