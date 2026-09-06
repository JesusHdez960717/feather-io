import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class AppFormInput extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final int? maxLength;
  final bool showCounter;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChange;
  final bool obscureText;
  final Widget? suffix;
  final Widget? prefix;
  final double? height;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double? borderWidth;

  const AppFormInput({
    required this.controller,
    this.label,
    this.hint,
    this.maxLength,
    this.showCounter = false,
    this.validator,
    this.inputFormatters,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    this.onChange,
    this.obscureText = false,
    this.suffix,
    this.prefix,
    this.height,
    this.contentPadding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    super.key,
  });

  @override
  State<AppFormInput> createState() => _AppFormInputState();
}

class _AppFormInputState extends State<AppFormInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: app.colors.neutral.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null || widget.showCounter)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: app.textTheme.bodyMedium!.copyWith(
                      color: app.colors.neutral.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (widget.showCounter)
                  Text(
                    _counterText,
                    style: app.textTheme.labelMedium?.copyWith(
                      color: app.colors.neutral.grey3,
                    ),
                  ),
              ],
            ),
          if (widget.label != null || widget.showCounter)
            app.dimensions.padding.s.gap(),
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color:
                  widget.backgroundColor ?? app.colors.primary.backgroundForm,
              borderRadius:
                  widget.borderRadius ?? app.dimensions.border.borderRadius.s,
              border: Border.all(
                color: widget.borderColor ?? app.colors.neutral.grey3,
                width: widget.borderWidth ?? app.dimensions.border.width.s,
              ),
            ),
            child: Row(
              children: [
                if (widget.prefix != null) widget.prefix!,
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    validator: widget.validator,
                    inputFormatters: widget.inputFormatters,
                    keyboardType: widget.keyboardType,
                    minLines: widget.minLines,
                    maxLines: widget.maxLines,
                    onChanged: widget.onChange,
                    obscureText: widget.obscureText,
                    style: app.textTheme.bodyLarge?.copyWith(
                      color: app.colors.neutral.white,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    maxLength: widget.maxLength,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: app.textTheme.bodyMedium?.copyWith(
                        color: app.colors.neutral.grey3,
                      ),
                      isDense: true,
                      contentPadding:
                          widget.contentPadding ??
                          EdgeInsets.symmetric(
                            horizontal: app.dimensions.padding.m,
                            vertical: app.dimensions.padding.m,
                          ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
                if (widget.suffix != null) widget.suffix!,
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _counterText {
    final length = widget.controller.text.length;
    if (widget.maxLength != null) {
      return '$length / ${widget.maxLength}';
    }
    return '$length';
  }
}
