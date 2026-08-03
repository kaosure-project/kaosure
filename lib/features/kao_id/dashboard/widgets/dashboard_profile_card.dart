import 'package:flutter/material.dart';

import '../../account/domain/entities/profile.dart';

class DashboardProfileCard extends StatelessWidget {
  const DashboardProfileCard({
    super.key,
    required this.profile,
    this.onTap,
  });

  final Profile profile;
  final VoidCallback? onTap;

  bool get _isVerified =>
      profile.accountLevel == 'verified' ||
      profile.accountLevel == 'business' ||
      profile.accountLevel == 'organization';

  String get _verificationText {
    switch (profile.accountLevel) {
      case 'verified':
        return 'ยืนยันตัวตนแล้ว';

      case 'business':
        return 'บัญชีธุรกิจ';

      case 'organization':
        return 'บัญชีองค์กร';

      case 'registered':
        return 'บัญชีลงทะเบียน';

      default:
        return 'บัญชีมาตรฐาน';
    }
  }

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

    final displayName =
        (profile.displayName ?? '').trim().isEmpty
            ? 'Kao ID User'
            : profile.displayName!;

    final username =
        (profile.username ?? '').trim().isEmpty
            ? '@ยังไม่ได้ตั้ง Username'
            : '@${profile.username}';

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
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: profile.avatarUrl != null &&
                          profile.avatarUrl!.isNotEmpty
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null ||
                          profile.avatarUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 42,
                          color: Colors.blue.shade700,
                        )
                      : null,
                ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 18),

                Chip(
                  avatar: Icon(
                    _isVerified
                        ? Icons.verified
                        : Icons.info_outline,
                    size: 18,
                    color: _isVerified
                        ? Colors.green
                        : Colors.orange,
                  ),
                  label: Text(_verificationText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}