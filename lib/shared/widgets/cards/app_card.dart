import 'package:flutter/material.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/radius/app_radius.dart';
import '../../design_system/shadows/app_shadows.dart';
import '../../design_system/spacing/app_spacing.dart';

/// Standard card used across Kao Ecosystem.
///
/// Supports:
/// - Clickable
/// - Custom padding
/// - Custom border
/// - Custom radius
/// - Custom shadow
/// - Animated state changes
final class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(
      AppSpacing.cardPadding,
    ),
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
    final radius = BorderRadius.circular(
      borderRadius ?? AppRadius.card,
    );

    final card = AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      curve: Curves.easeOut,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ??
            AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ??
              AppColors.border,
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
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}