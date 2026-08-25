import 'package:flutter/material.dart';

import '../../../../account/domain/entities/profile.dart';

final class ProfileCompletion extends StatelessWidget {
  const ProfileCompletion({
    super.key,
    required this.profile,
  });

  final Profile profile;

  bool get _isVerified =>
      profile.accountLevel == 'verified' ||
      profile.accountLevel == 'business' ||
      profile.accountLevel == 'organization';

  double get _progress {
    double value = 0.20;

    if ((profile.displayName ?? '').trim().isNotEmpty) {
      value += 0.20;
    }

    if ((profile.username ?? '').trim().isNotEmpty) {
      value += 0.20;
    }

    if ((profile.firstName ?? '').trim().isNotEmpty &&
        (profile.lastName ?? '').trim().isNotEmpty) {
      value += 0.20;
    }

    if (_isVerified) {
      value += 0.20;
    }

    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Account Completion ${(100 * _progress).round()}%',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}