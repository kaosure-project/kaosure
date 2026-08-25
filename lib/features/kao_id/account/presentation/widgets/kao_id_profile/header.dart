import 'package:flutter/material.dart';

import '../../../domain/entities/profile.dart';
import 'header/content.dart';
import 'header/description.dart';
import 'header/profile_action.dart';
import 'header/title.dart';

final class KaoIdProfileHeader extends StatelessWidget {
  const KaoIdProfileHeader({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeaderTitle(),

          const SizedBox(height: 24),

          HeaderContent(profile: profile),

          const SizedBox(height: 20),

          const ProfileDescription(),

          const SizedBox(height: 16),

          ProfileAction(profile: profile),
        ],
      ),
    );
  }
}
