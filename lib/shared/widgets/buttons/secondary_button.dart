import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';

enum SecondaryButtonSize {
  small,
  medium,
  large,
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.expand = true,
    this.size = SecondaryButtonSize.medium,
    this.borderColor,
    this.foregroundColor,
    this.backgroundColor,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  final bool isLoading;
  final bool isEnabled;
  final bool expand;

  final SecondaryButtonSize size;

  final Color? borderColor;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = switch (size) {
      SecondaryButtonSize.small => 44.0,
      SecondaryButtonSize.medium => 52.0,
      SecondaryButtonSize.large => 60.0,
    };

    final textStyle = switch (size) {
      SecondaryButtonSize.small => AppTextStyles.buttonSmall,
      SecondaryButtonSize.medium => AppTextStyles.buttonMedium,
      SecondaryButtonSize.large => AppTextStyles.buttonLarge,
    };

    final child = OutlinedButton(
      onPressed: (!isEnabled || isLoading) ? null : onPressed,
      style: OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: backgroundColor ?? Colors.transparent,
        foregroundColor: foregroundColor ?? AppColors.primary,
        disabledForegroundColor: AppColors.disabledForeground,
        side: BorderSide(
          color: borderColor ?? AppColors.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? SizedBox(
                key: const ValueKey('loading'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? AppColors.primary,
                  ),
                ),
              )
            : Row(
                key: const ValueKey('content'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: foregroundColor ?? AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    text,
                    style: textStyle.copyWith(
                      color: foregroundColor ?? AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );

    if (expand) {
      return SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: child,
      );
    }

    return SizedBox(
      height: buttonHeight,
      child: child,
    );
  }
}