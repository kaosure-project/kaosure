import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../shared/design_system/colors/app_colors.dart';

/// Masked text with an eye button; shows [revealed] while it is available.
class MaskedValue extends StatelessWidget {
  const MaskedValue({super.key, required this.masked, required this.onReveal, required this.onHide,
    this.revealed, this.loading = false});

  final String masked;
  final String? revealed;
  final bool loading;
  final VoidCallback onReveal;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final full = revealed;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
        child: SelectableText(
          full ?? masked,
          style: TextStyle(
            letterSpacing: 0.6,
            fontWeight: full == null ? FontWeight.w500 : FontWeight.w700,
            color: full == null ? AppColors.textPrimary : AppColors.kaoBlue,
          ),
        ),
      ),
      const SizedBox(width: 4),
      if (loading)
        const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else
        IconButton(
          tooltip: full == null ? l10n.piShow : l10n.piHide,
          onPressed: full == null ? onReveal : onHide,
          color: AppColors.kaoBlue,
          icon: Icon(full == null ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
        ),
    ]);
  }
}
