import 'package:flutter/material.dart';

import 'document_section_header.dart';
import 'identity_support_card.dart';

final class IdentitySupportSection extends StatelessWidget {
  const IdentitySupportSection({
    super.key,
    this.onPressed,
    this.title = 'ช่วยเหลือ',
    this.subtitle =
        'หากพบปัญหาในการยืนยันตัวตน สามารถติดต่อทีมงานได้',
  });

  final VoidCallback? onPressed;

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
        IdentitySupportCard(
          onPressed: onPressed,
        ),
      ],
    );
  }
}