import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'OK',
    this.cancelText,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;

  final String confirmText;
  final String? cancelText;

  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: AppTextStyles.titleLarge,
      ),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actionsPadding: const EdgeInsets.all(AppSpacing.md),
      actions: [
        if (cancelText != null)
          SecondaryButton(
            text: cancelText!,
            expand: false,
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
          ),
        PrimaryButton(
          text: confirmText,
          expand: false,
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
        ),
      ],
    );
  }
}