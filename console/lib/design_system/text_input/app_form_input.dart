import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Form field with label, counter, help and error.
/// States: normal, hover, focus, error (from [validator] or [errorText], e.g. a
/// 422 from the API; they look the same) and disabled. The enclosing [Form] validates it
class AppFormInput extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;

  /// Help text under the field; the error replaces it when there is one
  final String? helperText;

  /// Error from outside the [validator] (e.g. from the API). It wins over the validator's
  final String? errorText;
  final int? maxLength;
  final bool showCounter;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChange;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
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
    this.helperText,
    this.errorText,
    this.maxLength,
    this.showCounter = false,
    this.validator,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.onChange,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
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
  FocusNode? _ownFocusNode;
  bool _focused = false;
  bool _hovered = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
    _focusNode.addListener(_onFocusChange);
  /// On web Enter blurs the browser's input, and closing that connection
  /// unfocuses the field, so whatever the user types next goes nowhere. If the
  /// form is still on screen after submitting (a validation error, an API
  /// error), the focus goes back to the field.
  void _keepFocusAfterSubmit() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      _focusNode.requestFocus();
      // The browser selects the whole text on focus: typing would replace it
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    });
  }

  }

  @override
  void didUpdateWidget(covariant AppFormInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_update);
      widget.controller.addListener(_update);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  bool get _hasHelpRow =>
      widget.validator != null ||
      widget.helperText != null ||
      widget.errorText != null;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(widget.controller.text),
      builder: (field) {
        final error = widget.errorText ?? field.errorText;
        return Opacity(
          opacity: widget.enabled ? 1 : 0.55,
          child: Material(
            color: app.colors.neutral.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.label != null || widget.showCounter) ...[
                  _buildHeader(hasError: error != null),
                  app.dimensions.padding.s.gap(),
                ],
                _buildBox(field, hasError: error != null),
                if (_hasHelpRow) ...[
                  app.dimensions.padding.s.gap(),
                  _buildHelp(error),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool hasError}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.label != null)
          Flexible(
            child: Text(
              widget.label!,
              style: app.textTheme.bodyMedium!.copyWith(
                color: hasError
                    ? app.colors.primary.error
                    : app.colors.neutral.white,
                fontWeight: FontWeight.bold,
              ),
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
    );
  }

  Widget _buildBox(FormFieldState<String> field, {required bool hasError}) {
    final errorColor = app.colors.primary.error;
    final focusColor = app.colors.primary.primaryFaded;

    final Color borderColor;
    final List<BoxShadow> shadows;
    if (hasError) {
      borderColor = errorColor;
      shadows = [BoxShadow(color: errorColor, spreadRadius: 1)];
    } else if (_focused) {
      borderColor = focusColor;
      shadows = [BoxShadow(color: focusColor, spreadRadius: 1)];
    } else {
      borderColor = _hovered && widget.enabled
          ? app.colors.neutral.grey2
          : widget.borderColor ?? app.colors.neutral.grey3;
      shadows = const [];
    }

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? app.colors.primary.backgroundForm,
          borderRadius:
              widget.borderRadius ?? app.dimensions.border.borderRadius.s,
          border: Border.all(
            color: borderColor,
            width: widget.borderWidth ?? app.dimensions.border.width.s,
          ),
          boxShadow: shadows,
        ),
        child: Row(
          children: [
            if (widget.prefix != null) widget.prefix!,
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                inputFormatters: widget.inputFormatters,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                minLines: widget.minLines,
                maxLines: widget.maxLines,
                obscureText: widget.obscureText,
                onChanged: (value) {
                  field.didChange(value);
                  widget.onChange?.call(value);
                },
                onSubmitted: widget.onSubmitted == null
                    ? null
                    : (value) {
                        widget.onSubmitted!(value);
                        _keepFocusAfterSubmit();
                      },
                // By default Enter also unfocuses the field, after onSubmitted:
                // a form that fails validation would lose the focus it just asked for
                onEditingComplete: widget.onSubmitted == null ? null : () {},
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
                  disabledBorder: InputBorder.none,
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
    );
  }

  /// Fixed line under the field: the error (with an icon) or the help. It always
  /// takes its height so the form doesn't jump when an error appears
  Widget _buildHelp(String? error) {
    final style = app.textTheme.bodySmall;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 16),
      child: error != null
          ? Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.error_outline,
                      size: 14,
                      color: app.colors.primary.error,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error,
                      style: style?.copyWith(color: app.colors.primary.error),
                    ),
                  ),
                ],
              ),
            )
          : Text(
              widget.helperText ?? '',
              style: style?.copyWith(color: app.colors.neutral.grey3),
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
