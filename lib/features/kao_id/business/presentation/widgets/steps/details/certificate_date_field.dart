import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../domain/validators/business_registration_rules.dart';

/// Issue date of the company certificate; only dates within the last 6 months can be picked.
class CertificateDateField extends FormField<DateTime> {
  CertificateDateField({
    super.key,
    required DateTime? value,
    required DateTime today,
    required super.enabled,
    required ValueChanged<DateTime> onChanged,
  }) : super(
         initialValue: value,
         validator: (current) {
           if (current == null) return 'required';
           return BusinessRegistrationRules.isCertificateDateAccepted(current, today) ? null : 'old';
         },
         builder: (field) {
           final context = field.context;
           final l10n = AppLocalizations.of(context);
           final localizations = MaterialLocalizations.of(context);
           final current = field.value;
           final enabled = field.widget.enabled;
           final error = switch (field.errorText) {
             null => null,
             'required' => l10n.businessRegCertificateDateRequired,
             _ => l10n.businessRegCertificateTooOld,
           };
           final day = DateTime(today.year, today.month, today.day);
           Future<void> pick() async {
             final oldest = BusinessRegistrationRules.oldestCertificateDate(day);
             final picked = await showDatePicker(
               context: context,
               firstDate: oldest,
               lastDate: day,
               initialDate: current != null && !current.isBefore(oldest) && !current.isAfter(day) ? current : day,
             );
             if (picked == null) return;
             field.didChange(picked);
             onChanged(picked);
           }

           return InkWell(
             onTap: enabled ? pick : null,
             borderRadius: BorderRadius.circular(4),
             child: InputDecorator(
               isEmpty: current == null,
               decoration: InputDecoration(
                 labelText: l10n.businessRegCertificateDateLabel,
                 helperText: l10n.businessRegCertificateDateHelp,
                 helperMaxLines: 3,
                 errorText: error,
                 enabled: enabled,
                 suffixIcon: const Icon(Icons.calendar_today_outlined),
               ),
               child: current == null ? null : Text(localizations.formatMediumDate(current)),
             ),
           );
         },
       );
}
