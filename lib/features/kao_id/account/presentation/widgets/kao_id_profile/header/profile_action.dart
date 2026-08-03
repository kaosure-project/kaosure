import 'package:flutter/material.dart';

import '../../../../domain/entities/profile.dart';
import '../../../screens/edit_profile_screen.dart';

final class ProfileAction extends StatelessWidget {
  const ProfileAction({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(
                profile: profile,
              ),
            ),
          );
        },
        child: const Text('รายละเอียด >'),
      ),
    );
  }
}