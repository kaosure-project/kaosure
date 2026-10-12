import 'package:flutter/material.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';

/// Tab page layout: a coloured heading, then panels in two columns on wide screens.
class SectionBody extends StatelessWidget {
  const SectionBody({super.key, required this.icon, required this.color, required this.tint,
    required this.title, required this.description, required this.start, this.end = const [],
    this.onRefresh});

  final IconData icon;
  final Color color;
  final Color tint;
  final String title;
  final String description;
  final List<Widget> start;
  final List<Widget> end;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final heading = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 26),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(description, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      ])),
    ]);

    Widget stack(List<Widget> panels, double gap) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < panels.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              panels[i],
            ],
          ],
        );

    return LayoutBuilder(builder: (context, constraints) {
      final wide = end.isNotEmpty && constraints.maxWidth >= 840 &&
          MediaQuery.textScalerOf(context).scale(16) <= 24;
      final gap = wide ? 20.0 : 16.0;
      final list = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(wide ? 24 : 16),
        children: [
          heading,
          SizedBox(height: gap + 4),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: stack(start, gap)),
              SizedBox(width: gap),
              Expanded(child: stack(end, gap)),
            ])
          else
            stack([...start, ...end], gap),
        ],
      );
      final refresh = onRefresh;
      return refresh == null ? list : RefreshIndicator(onRefresh: refresh, child: list);
    });
  }
}
