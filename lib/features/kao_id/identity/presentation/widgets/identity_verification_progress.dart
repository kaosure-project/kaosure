import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import '../../domain/enums/document_status.dart';

final class IdentityVerificationProgress extends StatelessWidget {
  const IdentityVerificationProgress({
    super.key,
    required this.documents,
  });

  final List<IdentityDocument> documents;

  @override
  Widget build(BuildContext context) {
    final total = documents.length;

    final approved = documents
        .where(
          (document) =>
              document.status == DocumentStatus.approved,
        )
        .length;

    final progress =
        total == 0 ? 0.0 : approved / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'ความคืบหน้าการยืนยันตัวตน',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
            ),
            const SizedBox(height: 12),
            Text(
              '$approved / $total เอกสารผ่านการตรวจสอบ',
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}