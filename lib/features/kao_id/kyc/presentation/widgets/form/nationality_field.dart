import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../domain/reference/countries.dart';
import 'searchable_picker_field.dart';

/// Nationality picker storing the 3-letter country code.
class NationalityField extends StatelessWidget {
  const NationalityField({super.key, required this.fieldKey, required this.label,
    required this.value, required this.onChanged, this.enabled = true, this.showError = false});

  final String fieldKey;
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool showError;

  static List<PickerOption<String>> options(String languageCode) {
    final sorted = [...countries]
      ..sort((a, b) => a.name(languageCode).compareTo(b.name(languageCode)));
    return [
      for (final country in sorted)
        PickerOption(value: country.code, label: country.name(languageCode), detail: country.code,
          terms: '${country.en} ${country.th}'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SearchablePickerField<String>(
      fieldKey: fieldKey,
      label: label,
      icon: Icons.public,
      options: options(l10n.localeName.split('_').first),
      value: value,
      enabled: enabled,
      errorText: showError && countryByCode(value) == null ? l10n.nationalityRequired : null,
      onChanged: onChanged,
    );
  }
}
