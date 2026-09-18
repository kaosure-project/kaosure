import 'package:flutter/material.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/radius/app_radius.dart';
import '../../design_system/spacing/app_spacing.dart';
import '../../design_system/typography/app_text_styles.dart';

enum PrimaryButtonSize {
  small,
  medium,
  large,
}

/// Primary button used across Kao Ecosystem.
///
/// Features:
/// - Material 3
/// - Loading
/// - Disabled
/// - Icon
/// - Full width / Wrap content
/// - Responsive
/// - Hover support
final class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.expand = true,
    this.size = PrimaryButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String text;
  final VoidCallback? onPressed;

  final IconData? icon;

  final bool isLoading;
  final bool isEnabled;

  final bool expand;

  final PrimaryButtonSize size;

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      PrimaryButtonSize.small => 44.0,
      PrimaryButtonSize.medium => 52.0,
      PrimaryButtonSize.large => 60.0,
    };

    final textStyle = switch (size) {
      PrimaryButtonSize.small => AppTextStyles.buttonSmall,
      PrimaryButtonSize.medium => AppTextStyles.buttonMedium,
      PrimaryButtonSize.large => AppTextStyles.buttonLarge,
    };

    final child = FilledButton(
      onPressed: (!isEnabled || isLoading) ? null : onPressed,
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        animationDuration: const Duration(
          milliseconds: 180,
        ),
        mouseCursor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) {
              return SystemMouseCursors.forbidden;
            }

            return SystemMouseCursors.click;
          },
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.disabled;
            }

            return backgroundColor ?? AppColors.primary;
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.disabledForeground;
            }

            return foregroundColor ?? AppColors.onPrimary;
          },
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.button,
            ),
          ),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 200,
        ),
        child: isLoading
            ? SizedBox(
                key: const ValueKey('loading'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(
                    foregroundColor ?? AppColors.onPrimary,
                  ),
                ),
              )
            : Row(
                key: const ValueKey('content'),
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                    ),
                    const SizedBox(
                      width: AppSpacing.sm,
                    ),
                  ],
                  Text(
                    text,
                    style: textStyle.copyWith(
                      color: foregroundColor ?? AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: child,
    );
  }
}