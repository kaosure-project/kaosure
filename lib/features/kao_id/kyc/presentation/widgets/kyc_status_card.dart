import 'package:flutter/material.dart';

final class KycStatusCard extends StatelessWidget {
  const KycStatusCard({
    super.key,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.accountLevel,
    required this.status,
  });

  final String displayName;
  final String username;
  final String? avatarUrl;
  final String accountLevel;
  final String status;

  Color get _statusColor {
    switch (status) {
      case 'verified':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'verified':
        return Icons.verified;

      case 'pending':
        return Icons.hourglass_top;

      case 'rejected':
        return Icons.cancel;

      default:
        return Icons.info_outline;
    }
  }

  String get _statusText {
    switch (status) {
      case 'verified':
        return 'ยืนยันตัวตนแล้ว';

      case 'pending':
        return 'กำลังตรวจสอบ';

      case 'rejected':
        return 'ไม่ผ่านการตรวจสอบ';

      default:
        return 'ยังไม่ได้ยืนยันตัวตน';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundImage: avatarUrl != null &&
                      avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null ||
                      avatarUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 42,
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            Text(
              displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              username,
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            Chip(
              avatar: Icon(
                _statusIcon,
                color: _statusColor,
                size: 18,
              ),
              label: Text(
                _statusText,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              accountLevel,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}