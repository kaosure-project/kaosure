import 'package:flutter/material.dart';

import '../../../../domain/entities/profile.dart';
import 'profile_kao_id.dart';

final class ProfileInformation extends StatelessWidget {
  const ProfileInformation({super.key, required this.profile});

  final Profile profile;

  String get _accountLevel {
    switch (profile.accountLevel) {
      case 'verified':
        return 'ยืนยันตัวตนแล้ว';

      case 'business':
        return 'บัญชีธุรกิจ';

      case 'organization':
        return 'บัญชีองค์กร';

      case 'registered':
        return 'ลงทะเบียนแล้ว';

      default:
        return 'บัญชีมาตรฐาน';
    }
  }

  Color get _badgeColor {
    switch (profile.accountLevel) {
      case 'verified':
        return Colors.green;

      case 'business':
        return Colors.blue;

      case 'organization':
        return Colors.deepPurple;

      case 'registered':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.displayName ?? 'Display Name',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Chip(
          avatar: Icon(Icons.verified, color: _badgeColor, size: 18),
          label: Text(_accountLevel),
        ),

        const ProfileKaoId(),
      ],
    );
  }
}
