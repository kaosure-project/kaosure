import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'app_text_field.dart';

class AppEmailField extends StatelessWidget {
  const AppEmailField({
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
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      focusNode: focusNode,

      label: label ?? AppLocalizations.of(context).authEmail,
      hint: hint ?? AppLocalizations.of(context).authEmailHint,

      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,

      autofillHints: const [
        AutofillHints.email,
      ],

      prefixIcon: const Icon(Icons.email_outlined),

      validator: validator,

      onChanged: onChanged,
      onSubmitted: onSubmitted,

      enabled: enabled,
      readOnly: readOnly,
    );
  }
}
