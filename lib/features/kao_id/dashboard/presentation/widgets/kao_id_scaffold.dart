import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../shared/design_system/colors/app_colors.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import 'header/admin_center_button.dart';
import 'header/sign_out_button.dart';

/// Account navigation shared by the existing four destinations.
class KaoIdScaffold extends StatelessWidget {
  const KaoIdScaffold({super.key, required this.selectedIndex,
    required this.onSelected, required this.child});

  static const double maxContentWidth = 1120;

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.homeLabel, l10n.accountTitle, l10n.security, l10n.settings];
    return Scaffold(
      backgroundColor: AppColors.kaoPage,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          return Column(
            children: [
              const _BrandStripe(),
              Material(
                color: AppColors.surface,
                child: Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 12, compact ? 16 : 24, 0),
                    child: _Header(
                      compact: compact,
                      labels: labels,
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                    ),
                  ),
                )),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(child: Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth), child: child,
              ))),
            ],
          );
        }),
      ),
    );
  }
}

class _BrandStripe extends StatelessWidget {
  const _BrandStripe();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.kaoBlue, AppColors.kaoGreen]),
        ),
        child: SizedBox(height: 4, width: double.infinity),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.compact, required this.labels,
    required this.selectedIndex, required this.onSelected});

  final bool compact;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Image.asset('assets/images/kaosure_logo.png', height: compact ? 28 : 34,
            semanticLabel: 'KaoSure',
            errorBuilder: (_, _, _) => const SizedBox.shrink()),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.kaoId, overflow: TextOverflow.ellipsis,
            style: text.titleLarge?.copyWith(color: AppColors.kaoBlue, fontWeight: FontWeight.w700))),
          if (compact) ...[
            const AdminCenterButton(compact: true),
            const SignOutButton(compact: true),
          ],
          const NotificationBell(compact: true),
        ]),
        SizedBox(height: compact ? 8 : 16),
        Text(l10n.dashAccountInfoTitle,
          style: (compact ? text.titleLarge : text.headlineSmall)?.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _Tabs(labels: labels, selectedIndex: selectedIndex, onSelected: onSelected)),
            if (!compact) const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AdminCenterButton(),
                SizedBox(width: 8),
                SignOutButton(),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.labels, required this.selectedIndex, required this.onSelected});

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge;
    return Wrap(
      spacing: 4,
      children: [
        for (var i = 0; i < labels.length; i++)
          Semantics(
            selected: selectedIndex == i,
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(
                color: selectedIndex == i ? AppColors.kaoBlue : Colors.transparent,
                width: 3))),
              child: TextButton(
                onPressed: () => onSelected(i),
                style: TextButton.styleFrom(
                  foregroundColor: selectedIndex == i ? AppColors.kaoBlue : AppColors.textSecondary,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: const RoundedRectangleBorder(),
                  textStyle: label?.copyWith(
                    fontWeight: selectedIndex == i ? FontWeight.w700 : FontWeight.w500),
                ),
                child: Text(labels[i]),
              ),
            ),
          ),
      ],
    );
  }
}
