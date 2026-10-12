import 'package:flutter/material.dart';

class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Text(description,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 24),
      ],
    );
  }
}
