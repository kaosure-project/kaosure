import 'package:flutter/material.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';

/// Small outlined header action; collapses to an icon button when [compact].
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.compact = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool compact;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final indicator = const SizedBox(
      width: 18, height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    if (compact) {
      return IconButton(
        tooltip: label,
        onPressed: busy ? null : onPressed,
        color: AppColors.kaoBlue,
        icon: busy ? indicator : Icon(icon),
      );
    }
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy ? indicator : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.kaoBlue,
        side: const BorderSide(color: AppColors.kaoBlue),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
