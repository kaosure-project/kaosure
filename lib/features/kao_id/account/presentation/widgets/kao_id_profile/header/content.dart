import 'package:flutter/material.dart';

import '../../../../domain/entities/profile.dart';
import '../avatar/avatar.dart';
import '../information/information.dart';

final class HeaderContent extends StatelessWidget {
  const HeaderContent({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatar(
          profile: profile,
        ),

        const SizedBox(width: 20),

        Expanded(
          child: ProfileInformation(
            profile: profile,
          ),
        ),
      ],
    );
  }
}