import 'package:flutter/material.dart';

import '../../../../account/domain/entities/profile.dart';
import 'profile_status_chip.dart';

final class ProfileInformation extends StatelessWidget {
  const ProfileInformation({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayName =
        (profile.displayName ?? '').trim().isEmpty
            ? 'Kao ID User'
            : profile.displayName!;

    final username =
        (profile.username ?? '').trim().isEmpty
            ? '@ยังไม่ได้ตั้ง Username'
            : '@${profile.username}';

    return Column(
      children: [
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          username,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 18),

        ProfileStatusChip(
          profile: profile,
        ),
      ],
    );
  }
}