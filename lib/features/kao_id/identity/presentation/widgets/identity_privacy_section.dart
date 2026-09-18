import 'package:flutter/material.dart';

import 'document_section_header.dart';
import 'identity_privacy_notice_card.dart';

final class IdentityPrivacySection extends StatelessWidget {
  const IdentityPrivacySection({
    super.key,
    this.title = 'ความเป็นส่วนตัว',
    this.subtitle =
        'ข้อมูลส่วนบุคคลของคุณจะถูกจัดเก็บและใช้งานอย่างปลอดภัยตามนโยบายของ Kao ID',
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
        const IdentityPrivacyNoticeCard(),
      ],
    );
  }
}