import 'package:flutter/material.dart';

import '../../../../account/domain/entities/profile.dart';
import 'profile_avatar.dart';
import 'profile_completion.dart';
import 'profile_information.dart';

final class DashboardProfileCard extends StatelessWidget {
  const DashboardProfileCard({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ProfileAvatar(
                profile: profile,
              ),

              const SizedBox(height: 16),

              ProfileInformation(
                profile: profile,
              ),

              const SizedBox(height: 18),

              ProfileCompletion(
                profile: profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}