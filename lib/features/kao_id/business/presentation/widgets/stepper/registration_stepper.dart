import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../domain/entities/business_registration_step.dart';
import '../../utils/business_registration_texts.dart';

class RegistrationStepper extends StatelessWidget {
  const RegistrationStepper({
    super.key,
    required this.current,
    required this.canOpen,
    required this.onSelect,
  });

  final BusinessRegistrationStep current;
  final bool Function(BusinessRegistrationStep step) canOpen;
  final ValueChanged<BusinessRegistrationStep> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const steps = BusinessRegistrationStep.values;
    final counter = l10n.businessRegStepCounter(current.number, steps.length);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 440 &&
          MediaQuery.textScalerOf(context).scale(14) <= 18;
      return Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$counter · ${l10n.businessStepLabel(current)}',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            if (wide)
              Row(children: [
                for (final step in steps) ...[
                  Expanded(child: _StepItem(
                    step: step,
                    current: current,
                    enabled: step != current && canOpen(step),
                    onTap: () => onSelect(step),
                  )),
                  if (step != steps.last) const SizedBox(width: 8),
                ],
              ])
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: current.number / steps.length,
                  minHeight: 6,
                  semanticsLabel: counter,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.step,
    required this.current,
    required this.enabled,
    required this.onTap,
  });

  final BusinessRegistrationStep step;
  final BusinessRegistrationStep current;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = step.index < current.index;
    final active = step == current;
    final color = active || done ? scheme.primary : scheme.outlineVariant;
    return Semantics(
      button: enabled,
      selected: active,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 4, decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 8),
              Row(children: [
                Icon(done ? Icons.check_circle : Icons.circle_outlined, size: 16,
                    color: active || done ? scheme.primary : scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).businessStepLabel(step),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: active ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
