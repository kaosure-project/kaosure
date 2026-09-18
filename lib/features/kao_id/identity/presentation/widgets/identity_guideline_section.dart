import 'package:flutter/material.dart';

import 'document_section_header.dart';
import 'identity_guideline_card.dart';

final class IdentityGuidelineSection extends StatelessWidget {
  const IdentityGuidelineSection({
    super.key,
    this.title = 'แนวทางการยืนยันตัวตน',
    this.subtitle =
        'ศึกษาขั้นตอนและคำแนะนำก่อนส่งเอกสาร',
  });

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
        const IdentityGuidelineCard(),
      ],
    );
  }
}