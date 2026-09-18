import 'package:flutter/material.dart';

import '../../domain/enums/verification_status.dart';
import 'document_section_header.dart';
import 'identity_verification_result_card.dart';

final class IdentityVerificationStatusSection
    extends StatelessWidget {
  const IdentityVerificationStatusSection({
    super.key,
    required this.status,
    this.reason,
    this.onPrimaryAction,
    this.title = 'สถานะการยืนยันตัวตน',
    this.subtitle =
        'ตรวจสอบสถานะล่าสุดของการยืนยันตัวตน',
  });

  final VerificationStatus status;
  final String? reason;

  final VoidCallback? onPrimaryAction;

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        DocumentSectionHeader(
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 12),
        IdentityVerificationResultCard(
          status: status,
          reason: reason,
          onPrimaryAction: onPrimaryAction,
        ),
      ],
    );
  }
}