import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

/// Account navigation shared by the existing four destinations.
class KaoIdScaffold extends StatelessWidget {
  const KaoIdScaffold({super.key, required this.selectedIndex,
    required this.onSelected, required this.child});

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labels = [l10n.homeLabel, l10n.accountTitle, l10n.security, l10n.settings];
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: colors.surface,
              child: Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.kaoId, style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 4,
                        children: [
                          for (var i = 0; i < labels.length; i++)
                            Semantics(
                              selected: selectedIndex == i,
                              child: DecoratedBox(
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(
                                  color: selectedIndex == i ? colors.primary : Colors.transparent,
                                  width: 3))),
                                child: TextButton(
                                  onPressed: () => onSelected(i),
                                  style: TextButton.styleFrom(
                                    foregroundColor: selectedIndex == i ? colors.primary : colors.onSurfaceVariant,
                                    minimumSize: const Size(48, 48),
                                  ),
                                  child: Text(labels[i]),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
            ),
            const Divider(height: 1),
            Expanded(child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120), child: child,
            ))),
          ],
        ),
      ),
    );
  }
}
