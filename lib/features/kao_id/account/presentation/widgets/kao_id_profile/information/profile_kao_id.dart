import 'package:flutter/material.dart';

import '../../../../domain/entities/profile.dart';

final class ProfileKaoId extends StatelessWidget {
  const ProfileKaoId({super.key, required this.profile});

  final Profile profile;

  bool get _showKaoId {
    return profile.accountLevel == 'verified';
  }

  @override
  Widget build(BuildContext context) {
    if (!_showKaoId) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Kao ID : ${profile.username}',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
