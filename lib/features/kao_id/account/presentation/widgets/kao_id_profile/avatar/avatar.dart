import 'package:flutter/material.dart';

import '../../../../domain/entities/profile.dart';

final class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.avatarUrl;

    debugPrint('avatarUrl = $imageUrl');

    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return CircleAvatar(
      radius: 42,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
      onBackgroundImageError: hasImage
          ? (Object error, StackTrace? stackTrace) {
              debugPrint('Profile avatar error: $error');
            }
          : null,
      child: hasImage ? null : const Icon(Icons.person, size: 42),
    );
  }
}
