import 'package:flutter/material.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';

enum StatusTone { positive, pending, negative, neutral }

/// Coloured status label such as "Verified" or "Under review".
class StatusLabel extends StatelessWidget {
  const StatusLabel(this.text, {super.key, required this.tone});

  final String text;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (tone) {
      StatusTone.positive => (AppColors.kaoGreen, Icons.check_circle),
      StatusTone.pending => (const Color(0xFFB26A00), Icons.schedule),
      StatusTone.negative => (AppColors.error, Icons.error_outline),
      StatusTone.neutral => (AppColors.textSecondary, Icons.remove_circle_outline),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Flexible(child: Text(text, style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: color, fontWeight: FontWeight.w700))),
    ]);
  }
}

/// One linked item: icon and name, optional status, and a small action button.
class StatusRow extends StatelessWidget {
  const StatusRow({super.key, required this.icon, required this.title,
    required this.actionLabel, required this.onAction,
    this.iconColor = AppColors.kaoBlue, this.subtitle, this.status});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? status;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hint = subtitle;
    final name = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: iconColor, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        if (hint != null) Text(hint, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ])),
    ]);
    final trailing = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        ?status,
        OutlinedButton(
          onPressed: onAction,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.kaoBlue,
            side: BorderSide(color: onAction == null ? AppColors.border : AppColors.kaoBlue),
            minimumSize: const Size(96, 36),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 420) {
          return Row(children: [
            Expanded(child: name),
            const SizedBox(width: 16),
            trailing,
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          name,
          const SizedBox(height: 8),
          trailing,
        ]);
      }),
    );
  }
}
