import 'package:flutter/material.dart';
import '../../domain/enums/document_status.dart';
import '../../domain/entities/identity_document.dart';

final class DocumentActionButtons extends StatelessWidget {
  const DocumentActionButtons({
    super.key,
    required this.document,
    this.onSubmit,
    this.onEdit,
    this.onDelete,
    this.onHistory,
  });

  final IdentityDocument document;

  final VoidCallback? onSubmit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (document.status.canSubmit)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.upload),
              label: const Text('ส่งตรวจเอกสาร'),
            ),
          ),
        if (document.status.canSubmit)
          const SizedBox(height: 12),
        if (document.status.canEdit)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('แก้ไขข้อมูล'),
            ),
          ),
        if (document.status.canEdit)
          const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onHistory,
            icon: const Icon(Icons.history),
            label: const Text('ประวัติการตรวจสอบ'),
          ),
        ),
        if (document.status.canEdit) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('ลบเอกสาร'),
            ),
          ),
        ],
      ],
    );
  }
}