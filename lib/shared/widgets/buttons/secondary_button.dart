import 'package:flutter/material.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/radius/app_radius.dart';
import '../../design_system/spacing/app_spacing.dart';
import '../../design_system/typography/app_text_styles.dart';

enum SecondaryButtonSize {
  small,
  medium,
  large,
}

/// Secondary outlined button used across Kao Ecosystem.
///
/// Features:
/// - Material 3
/// - Loading
/// - Disabled
/// - Icon
/// - Full width / Wrap content
/// - Responsive
/// - Hover support
final class SecondaryButton extends StatelessWidget {
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
    final height = switch (size) {
      SecondaryButtonSize.small => 44.0,
      SecondaryButtonSize.medium => 52.0,
      SecondaryButtonSize.large => 60.0,
    };

    final textStyle = switch (size) {
      SecondaryButtonSize.small =>
        AppTextStyles.buttonSmall,

      SecondaryButtonSize.medium =>
        AppTextStyles.buttonMedium,

      SecondaryButtonSize.large =>
        AppTextStyles.buttonLarge,
    };

    final child = OutlinedButton(
      onPressed: (!isEnabled || isLoading)
          ? null
          : onPressed,

      style: ButtonStyle(
        elevation:
            const WidgetStatePropertyAll(0),

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

        backgroundColor:
            WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(
              WidgetState.disabled,
            )) {
              return Colors.transparent;
            }

            return backgroundColor ??
                Colors.transparent;
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

        side: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(
              WidgetState.disabled,
            )) {
              return BorderSide(
                color: AppColors.disabled,
              );
            }

            return BorderSide(
              color:
                  borderColor ??
                  AppColors.primary,
            );
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
                key: const ValueKey(
                  'loading',
                ),
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.4,
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

    return SizedBox(
      width: expand
          ? double.infinity
          : null,
      height: height,
      child: child,
    );
  }
}