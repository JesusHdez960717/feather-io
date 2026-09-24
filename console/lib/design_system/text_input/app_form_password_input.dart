import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class AppFormPasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChange;

  const AppFormPasswordInput({
    required this.controller,
    this.label,
    this.hint,
    this.validator,
    this.onChange,
    super.key,
  });

  @override
  State<AppFormPasswordInput> createState() => _AppFormPasswordInputState();
}

class _AppFormPasswordInputState extends State<AppFormPasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppFormInput(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      validator: widget.validator,
      onChange: widget.onChange,
      obscureText: _obscureText,
      suffix: IconButton(
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: app.colors.neutral.grey3,
          size: 20,
        ),
      ),
    );
  }
}
