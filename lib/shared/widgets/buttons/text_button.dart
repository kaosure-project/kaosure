import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';

enum AppTextButtonSize {
  small,
  medium,
  large,
}

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.expand = false,
    this.size = AppTextButtonSize.medium,
    this.foregroundColor,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  final bool isLoading;
  final bool isEnabled;
  final bool expand;

  final AppTextButtonSize size;

  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final textStyle = switch (size) {
      AppTextButtonSize.small => AppTextStyles.buttonSmall,
      AppTextButtonSize.medium => AppTextStyles.buttonMedium,
      AppTextButtonSize.large => AppTextStyles.buttonLarge,
    };

    final button = TextButton(
      onPressed: (!isEnabled || isLoading) ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor ?? AppColors.primary,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? SizedBox(
                key: const ValueKey('loading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
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
        child: button,
      );
    }

    return button;
  }
}