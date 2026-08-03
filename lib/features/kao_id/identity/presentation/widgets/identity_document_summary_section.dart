import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import 'document_section_header.dart';
import 'document_summary_card.dart';

final class IdentityDocumentSummarySection extends StatelessWidget {
  const IdentityDocumentSummarySection({
    super.key,
    required this.documents,
    this.title = 'สรุปเอกสาร',
    this.subtitle = 'ภาพรวมของเอกสารยืนยันตัวตน',
  });

  final List<IdentityDocument> documents;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentSectionHeader(
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 12),
        DocumentSummaryCard(
          documents: documents,
        ),
      ],
    );
  }
}