import 'package:flutter/material.dart';

import '../../../domain/entities/profile.dart';

import 'header.dart';

final class KaoIdProfileCard extends StatelessWidget {
  const KaoIdProfileCard({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Card(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: KaoIdProfileHeader(
          profile: profile,
        ),
      ),
    );
  }
}