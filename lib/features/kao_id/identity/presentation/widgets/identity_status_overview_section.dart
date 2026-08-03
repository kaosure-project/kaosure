import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import '../../domain/enums/verification_status.dart';
import 'document_section_header.dart';
import 'identity_overview_card.dart';
import 'identity_verification_status_section.dart';

final class IdentityStatusOverviewSection extends StatelessWidget {
  const IdentityStatusOverviewSection({
    super.key,
    required this.documents,
    required this.status,
    this.reason,
    this.onPrimaryAction,
    this.title = 'ภาพรวมการยืนยันตัวตน',
    this.subtitle =
        'ตรวจสอบสถานะและความคืบหน้าของการยืนยันตัวตน',
  });

  final List<IdentityDocument> documents;
  final VerificationStatus status;
  final String? reason;
  final VoidCallback? onPrimaryAction;

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
        IdentityOverviewCard(
          documents: documents,
        ),
        const SizedBox(height: 16),
        IdentityVerificationStatusSection(
          status: status,
          reason: reason,
          onPrimaryAction: onPrimaryAction,
        ),
      ],
    );
  }
}