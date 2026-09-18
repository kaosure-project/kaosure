import 'package:flutter/material.dart';

import 'document_section_header.dart';
import 'identity_information_banner.dart';

final class IdentityInformationSection extends StatelessWidget {
  const IdentityInformationSection({
    super.key,
    this.title = 'ข้อมูลสำคัญ',
    this.subtitle =
        'โปรดอ่านข้อมูลสำคัญก่อนดำเนินการยืนยันตัวตน',
    this.message =
        'การยืนยันตัวตนช่วยเพิ่มความน่าเชื่อถือของบัญชี และปลดล็อกความสามารถในการใช้งานบริการต่าง ๆ ของ Kao ID',
    this.icon = Icons.info_outline,
  });

  final String title;
  final String subtitle;
  final String message;
  final IconData icon;

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
        IdentityInformationBanner(
          title: title,
          message: message,
          icon: icon,
        ),
      ],
    );
  }
}