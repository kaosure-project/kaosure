import 'package:flutter/material.dart';

import '../../../../account/domain/entities/profile.dart';

final class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        profile.avatarUrl != null &&
        profile.avatarUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: 42,
      backgroundColor: Colors.blue.shade100,
      backgroundImage: hasAvatar
          ? NetworkImage(profile.avatarUrl!)
          : null,
      child: hasAvatar
          ? null
          : Icon(
              Icons.person,
              size: 42,
              color: Colors.blue.shade700,
            ),
    );
  }
}