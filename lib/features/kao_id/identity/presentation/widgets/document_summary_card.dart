import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import '../../domain/enums/document_status.dart';

final class DocumentSummaryCard extends StatelessWidget {
  const DocumentSummaryCard({
    super.key,
    required this.documents,
  });

  final List<IdentityDocument> documents;

  @override
  Widget build(BuildContext context) {
    final total = documents.length;
    final approved = documents
        .where((e) => e.status == DocumentStatus.approved)
        .length;
    final pending = documents
        .where((e) => e.status == DocumentStatus.pendingReview)
        .length;
    final rejected = documents
        .where((e) => e.status == DocumentStatus.rejected)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สรุปเอกสาร',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              title: 'ทั้งหมด',
              value: total,
            ),
            const Divider(),
            _SummaryRow(
              title: 'ผ่านการตรวจ',
              value: approved,
            ),
            const Divider(),
            _SummaryRow(
              title: 'กำลังตรวจสอบ',
              value: pending,
            ),
            const Divider(),
            _SummaryRow(
              title: 'ไม่ผ่าน',
              value: rejected,
            ),
          ],
        ),
      ),
    );
  }
}

final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.title,
    required this.value,
  });

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}