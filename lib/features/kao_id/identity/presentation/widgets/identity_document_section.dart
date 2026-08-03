import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import 'document_list_view.dart';
import 'document_section_header.dart';

final class IdentityDocumentSection extends StatelessWidget {
  const IdentityDocumentSection({
    super.key,
    required this.documents,
    this.onDocumentTap,
    this.title = 'เอกสารยืนยันตัวตน',
    this.subtitle = 'เอกสารที่ใช้สำหรับการตรวจสอบตัวตน',
  });

  final List<IdentityDocument> documents;
  final ValueChanged<IdentityDocument>? onDocumentTap;

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
        DocumentListView(
          documents: documents,
          onTap: onDocumentTap,
        ),
      ],
    );
  }
}