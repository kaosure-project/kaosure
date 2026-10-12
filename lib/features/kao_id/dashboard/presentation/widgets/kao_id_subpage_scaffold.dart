import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import 'kao_id_scaffold.dart';

/// Kao ID frame for pages opened from the account area: brand stripe, a white
/// header with back, logo and a badge naming the area, icon [actions], and
/// content capped to the account width.
class KaoIdSubpageScaffold extends StatelessWidget {
  const KaoIdSubpageScaffold({super.key, required this.badgeIcon, required this.badgeLabel,
    required this.child, this.actions = const []});

  final IconData badgeIcon;
  final String badgeLabel;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.kaoPage,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          return Column(children: [
            const BrandStripe(),
            Material(
              color: AppColors.surface,
              child: Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: KaoIdScaffold.maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16, vertical: 8),
                  child: Row(children: [
                    if (canPop)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        color: AppColors.textSecondary,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      )
                    else
                      const SizedBox(width: 8),
                    Image.asset('assets/images/kaosure_logo.png', height: compact ? 26 : 32,
                      semanticLabel: 'KaoSure',
                      errorBuilder: (_, _, _) => const SizedBox.shrink()),
                    const SizedBox(width: 10),
                    if (!compact) ...[
                      Text(l10n.kaoId, style: text.titleLarge?.copyWith(
                        color: AppColors.kaoBlue, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                    ],
                    Flexible(child: _AreaBadge(icon: badgeIcon, label: badgeLabel)),
                    const Spacer(),
                    ...actions,
                  ]),
                ),
              )),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: KaoIdScaffold.maxContentWidth),
              child: child,
            ))),
          ]);
        }),
      ),
    );
  }
}

class _AreaBadge extends StatelessWidget {
  const _AreaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.kaoSlateSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: AppColors.kaoSlate),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.kaoSlate, fontWeight: FontWeight.w700))),
        ]),
      );
}
