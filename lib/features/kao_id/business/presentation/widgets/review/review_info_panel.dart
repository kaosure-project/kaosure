import 'package:flutter/material.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../../dashboard/presentation/widgets/home/dashboard_panel.dart';

/// White panel of label/value rows; labels sit beside values when there is room.
class ReviewInfoPanel extends StatelessWidget {
  const ReviewInfoPanel({super.key, required this.title, required this.icon,
    required this.rows, this.color = AppColors.kaoBlue});

  final String title;
  final IconData icon;
  final Color color;
  final List<(String label, String value)> rows;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DashboardPanel(
      title: title,
      icon: icon,
      iconColor: color,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: LayoutBuilder(builder: (context, constraints) {
        final inline = constraints.maxWidth >= 380;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _row(rows[i], inline, text),
            ),
          ],
        ]);
      }),
    );
  }

  Widget _row((String, String) row, bool inline, TextTheme text) {
    final (label, value) = row;
    final labelText = Text(label, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary));
    final valueText = SelectableText(value, style: text.bodyLarge?.copyWith(
      color: AppColors.textPrimary, fontWeight: FontWeight.w600));
    if (label.isEmpty) return valueText;
    if (!inline) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        labelText,
        const SizedBox(height: 2),
        valueText,
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 150, child: labelText),
      const SizedBox(width: 12),
      Expanded(child: valueText),
    ]);
  }
}
