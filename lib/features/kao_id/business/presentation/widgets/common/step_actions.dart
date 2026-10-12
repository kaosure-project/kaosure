import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

/// Back on the left, the single primary action on the right.
class StepActions extends StatelessWidget {
  const StepActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.busy = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
      onPressed: busy ? null : onPrimary,
      child: busy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(primaryLabel),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Row(
        children: [
          if (onBack != null)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: busy ? null : onBack,
              child: Text(l10n.businessRegBack),
            ),
          const Spacer(),
          Flexible(flex: 3, child: primary),
        ],
      ),
    );
  }
}
