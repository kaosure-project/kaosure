import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../common/step_actions.dart';
import '../../common/step_header.dart';

/// The applicant confirms they are a director named in the company certificate.
class DirectorAuthorityStep extends StatelessWidget {
  const DirectorAuthorityStep({
    super.key,
    required this.declared,
    required this.busy,
    required this.onDeclaredChanged,
    required this.onBack,
    required this.onContinue,
  });

  final bool declared;
  final bool busy;
  final ValueChanged<bool> onDeclaredChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeader(title: l10n.businessRegAuthorityHeading, description: l10n.businessRegAuthorityDescription),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.businessRegAuthorityKaoIdVerified, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      l10n.businessRegAuthorityMatchHelp,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          key: const ValueKey('director-declaration'),
          value: declared,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: busy ? null : (value) => onDeclaredChanged(value ?? false),
          title: Text(l10n.businessRegDirectorDeclaration, style: theme.textTheme.bodyMedium),
        ),
        StepActions(
          primaryLabel: l10n.businessRegContinue,
          onPrimary: declared ? onContinue : null,
          onBack: onBack,
          busy: busy,
        ),
      ],
    );
  }
}
