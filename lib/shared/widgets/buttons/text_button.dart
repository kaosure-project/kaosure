import 'package:flutter/material.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/spacing/app_spacing.dart';
import '../../design_system/typography/app_text_styles.dart';

enum AppTextButtonSize {
  small,
  medium,
  large,
}

/// Standard text button used across Kao Ecosystem.
///
/// Features:
/// - Material 3
/// - Loading
/// - Disabled
/// - Icon
/// - Full width / Wrap content
/// - Responsive
/// - Hover support
final class AppTextButton extends StatelessWidget {
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
      AppTextButtonSize.small =>
        AppTextStyles.buttonSmall,

      AppTextButtonSize.medium =>
        AppTextStyles.buttonMedium,

      AppTextButtonSize.large =>
        AppTextStyles.buttonLarge,
    };

    final child = TextButton(
      onPressed: (!isEnabled || isLoading)
          ? null
          : onPressed,

      style: ButtonStyle(
        animationDuration: const Duration(
          milliseconds: 180,
        ),

        mouseCursor:
            WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(
              WidgetState.disabled,
            )) {
              return SystemMouseCursors.forbidden;
            }

            return SystemMouseCursors.click;
          },
        ),

        foregroundColor:
            WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(
              WidgetState.disabled,
            )) {
              return AppColors.disabledForeground;
            }

            return foregroundColor ??
                AppColors.primary;
          },
        ),

        overlayColor:
            WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(
                  WidgetState.hovered,
                ) ||
                states.contains(
                  WidgetState.focused,
                ) ||
                states.contains(
                  WidgetState.pressed,
                )) {
              return (foregroundColor ??
                      AppColors.primary)
                  .withValues(alpha: 0.08);
            }

            return Colors.transparent;
          },
        ),
      ),

      child: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 200,
        ),

        child: isLoading
            ? SizedBox(
                key: const ValueKey(
                  'loading',
                ),
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor:
                      AlwaysStoppedAnimation(
                    foregroundColor ??
                        AppColors.primary,
                  ),
                ),
              )
            : Row(
                key: const ValueKey(
                  'content',
                ),
                mainAxisSize:
                    MainAxisSize.min,
                mainAxisAlignment:
                    MainAxisAlignment.center,
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
                      color:
                          foregroundColor ??
                              AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );

    if (!expand) {
      return child;
    }

    return SizedBox(
      width: double.infinity,
      child: child,
    );
  }
}