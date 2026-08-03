import 'package:flutter/material.dart';
import '../../domain/enums/document_type_enum.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/enums/document_status.dart';

final class DocumentInformationCard extends StatelessWidget {
  const DocumentInformationCard({
    super.key,
    required this.document,
  });

  final IdentityDocument document;

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
  document.documentType.label,
  style: Theme.of(context)
      .textTheme
      .titleLarge,
),
            const Divider(height: 32),
            const Divider(height: 32),
            _Row(
              title: 'สถานะเอกสาร',
              value: document.status.label,
            ),
            const SizedBox(height: 12),
            _Row(
              title: 'เลขเอกสาร',
              value: document.documentNumber.value,
            ),
            const SizedBox(height: 12),
            _Row(
              title: 'วันที่ออก',
              value: _formatDate(
                document.issuedDate?.value,
              ),
            ),
            const SizedBox(height: 12),
            _Row(
              title: 'วันหมดอายุ',
              value: _formatDate(
                document.expiryDate?.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value),
        ),
      ],
    );
  }
}