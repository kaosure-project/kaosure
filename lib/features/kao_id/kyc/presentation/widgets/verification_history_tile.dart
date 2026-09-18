import 'package:flutter/material.dart';

final class VerificationHistoryTile extends StatelessWidget {
  const VerificationHistoryTile({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.history,
      ),
      title: const Text(
        'ประวัติการยืนยันตัวตน',
      ),
      subtitle: const Text(
        'ดูประวัติการตรวจสอบและการเปลี่ยนแปลง',
      ),
      trailing: const Icon(
        Icons.chevron_right,
      ),
      onTap: onTap,
    );
  }
}