import 'package:flutter/material.dart';

import 'document_section_header.dart';
import 'identity_security_notice_card.dart';

final class IdentitySecuritySection extends StatelessWidget {
  const IdentitySecuritySection({
    super.key,
    this.title = 'ความปลอดภัย',
    this.subtitle =
        'ข้อมูลและเอกสารของคุณได้รับการปกป้องตามมาตรฐานของ Kao ID',
  });

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
        const IdentitySecurityNoticeCard(),
      ],
    );
  }
}