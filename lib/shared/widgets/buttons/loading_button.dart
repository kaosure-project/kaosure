import 'package:flutter/material.dart';

import '../../design_system/colors/app_colors.dart';
import '../../design_system/radius/app_radius.dart';

/// Full screen loading button used during async operations.
///
/// Example:
/// Login
/// Register
/// Upload KYC
/// Save Profile
/// Checkout
final class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    this.text = 'กำลังดำเนินการ...',
    this.height = 52,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String text;

  final double height;

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          elevation: 0,
          disabledBackgroundColor:
              backgroundColor ?? AppColors.primary,
          disabledForegroundColor:
              foregroundColor ?? AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.button,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(
                  foregroundColor ??
                      AppColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(text),
          ],
        ),
      ),
    );
  }
}