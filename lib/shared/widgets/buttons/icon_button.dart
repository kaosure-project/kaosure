import 'package:flutter/material.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/radius/app_radius.dart';

enum AppIconButtonSize {
  small,
  medium,
  large,
}

/// Standard icon button used across Kao Ecosystem.
///
/// Features:
/// - Material 3
/// - Loading
/// - Disabled
/// - Filled / Outlined
/// - Responsive
/// - Hover support
final class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isLoading = false,
    this.isEnabled = true,
    this.filled = false,
    this.size = AppIconButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  final String? tooltip;

  final bool isLoading;
  final bool isEnabled;

  final bool filled;

  final AppIconButtonSize size;

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final buttonSize = switch (size) {
      AppIconButtonSize.small => 40.0,
      AppIconButtonSize.medium => 48.0,
      AppIconButtonSize.large => 56.0,
    };

    final iconSize = switch (size) {
      AppIconButtonSize.small => 18.0,
      AppIconButtonSize.medium => 22.0,
      AppIconButtonSize.large => 26.0,
    };

    final Widget button = IconButton(
      onPressed: (!isEnabled || isLoading)
          ? null
          : onPressed,
      tooltip: tooltip,
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(
          Size.square(buttonSize),
        ),
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
            if (!filled) {
              return Colors.transparent;
            }

            if (states.contains(
              WidgetState.disabled,
            )) {
              return AppColors.disabled;
            }

            return backgroundColor ??
                AppColors.primary;
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
                (filled
                    ? AppColors.onPrimary
                    : AppColors.primary);
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
      icon: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 200,
        ),
        child: isLoading
            ? SizedBox(
                key: const ValueKey('loading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor:
                      AlwaysStoppedAnimation(
                    foregroundColor ??
                        (filled
                            ? AppColors.onPrimary
                            : AppColors.primary),
                  ),
                ),
              )
            : Icon(
                icon,
                key: const ValueKey('icon'),
                size: iconSize,
              ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }

    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}