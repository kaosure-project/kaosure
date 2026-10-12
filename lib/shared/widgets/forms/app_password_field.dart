import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'app_text_field.dart';

class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.label,
    this.hint,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final FormFieldValidator<String>? validator;

  final bool enabled;
  final bool readOnly;

  final String? label;
  final String? hint;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,

      label: widget.label ?? AppLocalizations.of(context).password,
      hint: widget.hint ?? AppLocalizations.of(context).authPasswordHint,

      obscureText: _obscureText,

      textInputAction: TextInputAction.done,

      autofillHints: const [
        AutofillHints.password,
      ],

      prefixIcon: const Icon(Icons.lock_outline),

      suffixIcon: IconButton(
        tooltip: _obscureText
            ? AppLocalizations.of(context).authShowPassword
            : AppLocalizations.of(context).authHidePassword,
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),

      validator: widget.validator,

      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,

      enabled: widget.enabled,
      readOnly: widget.readOnly,
    );
  }
}
