import 'package:flutter/material.dart';

import '../../../../../shared/design_system/colors/app_colors.dart';

/// Label / value line; stacks vertically on narrow panels.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.child, this.badge, this.last = false});

  final String label;
  final Widget child;
  final Widget? badge;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final labelText = Text(label, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary));
    final value = Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DefaultTextStyle.merge(style: text.bodyLarge?.copyWith(color: AppColors.textPrimary), child: child),
        ?badge,
      ],
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(builder: (context, constraints) => constraints.maxWidth >= 380
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(width: 140, child: labelText),
                const SizedBox(width: 12),
                Expanded(child: value),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                labelText,
                const SizedBox(height: 4),
                value,
              ])),
      ),
      if (!last) const Divider(height: 1),
    ]);
  }
}
