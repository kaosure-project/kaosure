import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.shadow = AppShadows.sm,
  });

  final Widget child;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  final VoidCallback? onTap;

  final Color? backgroundColor;
  final Color? borderColor;

  final double? borderRadius;

  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppRadius.card,
        ),
        border: Border.all(
          color: borderColor ?? AppColors.border,
        ),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppRadius.card,
        ),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
