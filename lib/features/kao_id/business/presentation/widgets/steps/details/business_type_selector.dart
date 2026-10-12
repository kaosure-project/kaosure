import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../domain/entities/business_type.dart';

class BusinessTypeSelector extends StatelessWidget {
  const BusinessTypeSelector({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget option(String type, IconData icon, String title, String hint) {
      final selected = value == type;
      final scheme = theme.colorScheme;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onChanged == null ? null : () => onChanged!(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(children: [
              Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(hint, style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant)),
                ],
              )),
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? scheme.primary : scheme.outline),
            ]),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.businessRegTypeLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        option(BusinessType.registeredBusiness, Icons.apartment_outlined,
            l10n.businessRegTypeCompany, l10n.businessRegTypeCompanyHint),
        const SizedBox(height: 12),
        option(BusinessType.organization, Icons.volunteer_activism_outlined,
            l10n.businessRegTypeOrganization, l10n.businessRegTypeOrganizationHint),
      ],
    );
  }
}
