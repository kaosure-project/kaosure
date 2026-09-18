import 'package:flutter/material.dart';

import '../../domain/entities/verification.dart';

import 'permission_card.dart';

final class PermissionSection extends StatelessWidget {
  const PermissionSection({
    super.key,
    required this.verification,
  });

  final Verification? verification;

  @override
  Widget build(BuildContext context) {
    final emailVerified =
        verification?.emailVerified ?? false;

    final phoneVerified =
        verification?.phoneVerified ?? false;

    final identityVerified =
        verification?.identityCardStatus == 'verified';

    final bankVerified =
        verification?.bankStatus == 'verified';

    return PermissionCard(
      permissions: [
        const PermissionItem(
          title: 'เข้าสู่ระบบ',
          enabled: true,
        ),
        const PermissionItem(
          title: 'แก้ไขโปรไฟล์',
          enabled: true,
        ),
        PermissionItem(
          title: 'ยืนยันอีเมล',
          enabled: emailVerified,
        ),
        PermissionItem(
          title: 'ยืนยันเบอร์โทรศัพท์',
          enabled: phoneVerified,
        ),
        const PermissionItem(
          title: 'ซื้อสินค้า',
          enabled: true,
        ),
        PermissionItem(
          title: 'ขายสินค้า',
          enabled: identityVerified,
        ),
        PermissionItem(
          title: 'ถอนเงิน',
          enabled: bankVerified,
        ),
        PermissionItem(
          title: 'KaoPay',
          enabled: identityVerified && bankVerified,
        ),
        PermissionItem(
          title: 'Marketplace',
          enabled: emailVerified && phoneVerified,
        ),
        PermissionItem(
          title: 'Auction',
          enabled: identityVerified && bankVerified,
        ),
      ],
    );
  }
}