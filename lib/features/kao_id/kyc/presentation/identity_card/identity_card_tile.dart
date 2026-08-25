import 'package:flutter/material.dart';

final class IdentityCardTile extends StatelessWidget {
  const IdentityCardTile({
    super.key,
    required this.status,
    required this.expiryDate,
    required this.onTap,
  });

  final String status;
  final DateTime? expiryDate;
  final VoidCallback onTap;

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

  String get _statusText {
    switch (status) {
      case 'verified':
        return 'ผ่านการยืนยัน';

      case 'pending':
        return 'กำลังตรวจสอบ';

      case 'rejected':
        return 'ไม่ผ่าน';

      default:
        return 'ยังไม่ได้เพิ่ม';
    }
  }

  String get _expiryText {
    if (expiryDate == null) {
      return '';
    }

    return '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.badge_outlined,
        color: _statusColor,
      ),
      title: const Text(
        'บัตรประชาชน',
      ),
      subtitle: expiryDate == null
          ? Text(_statusText)
          : Text(
              'หมดอายุ $_expiryText',
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _statusText,
            style: TextStyle(
              color: _statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}