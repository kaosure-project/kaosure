import 'package:flutter/material.dart';

import '../../domain/entities/document_type.dart';
import '../../domain/entities/identity_document.dart';
import 'document_section_header.dart';
import 'identity_requirement_card.dart';

final class IdentityRequirementSection extends StatelessWidget {
  const IdentityRequirementSection({
    super.key,
    required this.documentTypes,
    required this.documents,
    this.title = 'ข้อกำหนดในการยืนยันตัวตน',
    this.subtitle = 'ตรวจสอบเอกสารที่จำเป็นสำหรับการยืนยันตัวตน',
  });

  final List<DocumentType> documentTypes;
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
        IdentityRequirementCard(
          documentTypes: documentTypes,
          documents: documents,
        ),
      ],
    );
  }
}