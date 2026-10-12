import 'package:flutter/material.dart';

/// Cards grow vertically with translated labels and accessibility text sizes.
class QuickActionsLayout extends StatelessWidget {
  const QuickActionsLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final minimumWidth = 160 * textScale.clamp(1.0, 2.0);
        final columns = ((constraints.maxWidth + 12) / (minimumWidth + 12))
            .floor()
            .clamp(1, children.length);
        final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
