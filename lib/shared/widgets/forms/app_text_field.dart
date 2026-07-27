import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.autofillHints,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  final FormFieldValidator<String>? validator;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  final int? maxLength;
  final int maxLines;

  final bool enabled;
  final bool readOnly;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,

      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,

      keyboardType: keyboardType,
      textInputAction: textInputAction,

      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,

      inputFormatters: inputFormatters,
      autofillHints: autofillHints,

      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}