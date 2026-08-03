import 'package:flutter/material.dart';

final class EmptyDocumentState extends StatelessWidget {
  const EmptyDocumentState({
    super.key,
    this.title = 'ยังไม่มีเอกสาร',
    this.message = 'กรุณาอัปโหลดเอกสารเพื่อเริ่มการยืนยันตัวตน',
    this.buttonText,
    this.onPressed,
  });

  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.upload_file),
                label: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}