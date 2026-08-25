import 'package:flutter/material.dart';

import '../../../../account/domain/entities/profile.dart';

final class ProfileStatusChip extends StatelessWidget {
  const ProfileStatusChip({
    super.key,
    required this.profile,
  });

  final Profile profile;

  bool get _isVerified =>
      profile.accountLevel == 'verified' ||
      profile.accountLevel == 'business' ||
      profile.accountLevel == 'organization';

  String get _verificationText {
    switch (profile.accountLevel) {
      case 'verified':
        return 'ยืนยันตัวตนแล้ว';

      case 'business':
        return 'บัญชีธุรกิจ';

      case 'organization':
        return 'บัญชีองค์กร';

      case 'registered':
        return 'บัญชีลงทะเบียน';

      default:
        return 'บัญชีมาตรฐาน';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        _isVerified
            ? Icons.verified
            : Icons.info_outline,
        size: 18,
        color: _isVerified
            ? Colors.green
            : Colors.orange,
      ),
      label: Text(
        _verificationText,
      ),
    );
  }
}