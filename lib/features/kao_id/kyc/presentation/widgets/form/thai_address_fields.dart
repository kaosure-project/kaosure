import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../domain/entities/thai_address.dart';
import '../../../domain/reference/thai_provinces.dart';
import 'searchable_picker_field.dart';

/// Holds the text of a [ThaiAddressFields] group.
class ThaiAddressController {
  final line = TextEditingController();
  final subdistrict = TextEditingController();
  final district = TextEditingController();
  final postalCode = TextEditingController();
  String? province;

  ThaiAddress get value => ThaiAddress(
        line: line.text.trim(),
        subdistrict: subdistrict.text.trim(),
        district: district.text.trim(),
        province: province ?? '',
        postalCode: postalCode.text.trim(),
      );

  void clear() {
    for (final field in [line, subdistrict, district, postalCode]) {
      field.clear();
    }
    province = null;
  }

  void dispose() {
    for (final field in [line, subdistrict, district, postalCode]) {
      field.dispose();
    }
  }
}

/// Thai address split into house/road, subdistrict, district, province and
/// postal code. Inputs are keyed `<keyPrefix>-address_line`, `-subdistrict`,
/// `-district`, `-province` and `-postal_code`.
class ThaiAddressFields extends StatelessWidget {
  const ThaiAddressFields({super.key, required this.controller, required this.keyPrefix,
    required this.enabled, required this.showErrors, required this.onChanged});

  final ThaiAddressController controller;
  final String keyPrefix;
  final bool enabled;
  final bool showErrors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = l10n.localeName.split('_').first;
    final invalid = showErrors ? controller.value.invalidFields : const <ThaiAddressField>{};

    Widget text(String key, TextEditingController field, String label, ThaiAddressField which,
        {int maxLength = 100, bool digits = false}) => TextField(
      key: ValueKey('$keyPrefix-$key'),
      controller: field,
      enabled: enabled,
      maxLength: maxLength,
      onChanged: (_) => onChanged(),
      textInputAction: TextInputAction.next,
      keyboardType: digits ? TextInputType.number : TextInputType.streetAddress,
      inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorMaxLines: 2,
        errorText: invalid.contains(which)
            ? (which == ThaiAddressField.postalCode ? l10n.idPostalCodeInvalid : l10n.idAddressRequired)
            : null,
      ),
    );

    final province = SearchablePickerField<String>(
      fieldKey: '$keyPrefix-province',
      label: l10n.piProvince,
      enabled: enabled,
      value: controller.province,
      errorText: invalid.contains(ThaiAddressField.province) ? l10n.provinceRequired : null,
      options: [
        for (final p in thaiProvinces)
          PickerOption(value: p.th, label: p.label(language), terms: '${p.th} ${p.en}'),
      ],
      onChanged: (value) {
        controller.province = value;
        onChanged();
      },
    );

    final subdistrict = text('subdistrict', controller.subdistrict, l10n.piSubdistrict, ThaiAddressField.subdistrict);
    final district = text('district', controller.district, l10n.piDistrict, ThaiAddressField.district);
    final postal = text('postal_code', controller.postalCode, l10n.piPostalCode, ThaiAddressField.postalCode,
      maxLength: 5, digits: true);

    return LayoutBuilder(builder: (context, constraints) {
      final pair = constraints.maxWidth >= 480;
      Widget row(Widget a, Widget b) => pair
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: a), const SizedBox(width: 12), Expanded(child: b),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 4), b]);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        text('address_line', controller.line, l10n.piAddressLine, ThaiAddressField.line, maxLength: 300),
        const SizedBox(height: 4),
        row(subdistrict, district),
        const SizedBox(height: 4),
        row(Padding(padding: const EdgeInsets.only(bottom: 22), child: province), postal),
      ]);
    });
  }
}
