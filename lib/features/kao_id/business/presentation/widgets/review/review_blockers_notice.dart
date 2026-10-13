import 'package:flutter/material.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

/// Facts that stop approval; the reviewer can still reject with a reason.
class ReviewBlockersNotice extends StatelessWidget {
  const ReviewBlockersNotice({super.key, required this.title, required this.messages});

  final String title;
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_outlined, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(color: scheme.error, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          for (final message in messages) ...[
            const SizedBox(height: 6),
            Text('• $message', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
          ],
        ],
      ),
    );
  }
}
