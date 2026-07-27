import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';

enum PrimaryButtonSize {
  small,
  medium,
  large,
}

class PrimaryButton extends StatelessWidget {
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
    final buttonHeight = switch (size) {
      PrimaryButtonSize.small => 44.0,
      PrimaryButtonSize.medium => 52.0,
      PrimaryButtonSize.large => 60.0,
    };

    final textStyle = switch (size) {
      PrimaryButtonSize.small => AppTextStyles.buttonSmall,
      PrimaryButtonSize.medium => AppTextStyles.buttonMedium,
      PrimaryButtonSize.large => AppTextStyles.buttonLarge,
    };

    final child = ElevatedButton(
      onPressed: (!isEnabled || isLoading) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? AppColors.onPrimary,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: AppColors.disabledForeground,
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
                    foregroundColor ?? AppColors.onPrimary,
                  ),
                ),
              )
            : Row(
                key: const ValueKey('content'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppSpacing.sm),
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