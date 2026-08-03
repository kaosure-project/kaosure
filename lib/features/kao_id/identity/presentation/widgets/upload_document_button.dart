import 'package:flutter/material.dart';

final class UploadDocumentButton extends StatelessWidget {
  const UploadDocumentButton({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.upload_file_rounded,
        ),
        label: const Text(
          'เพิ่มเอกสาร',
        ),
      ),
    );
  }
}