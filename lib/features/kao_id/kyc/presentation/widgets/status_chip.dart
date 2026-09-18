import 'package:flutter/material.dart';

final class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    late final Color backgroundColor;
    late final Color foregroundColor;
    late final IconData icon;
    late final String text;

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = const Color(0xFFE8F5E9);
        foregroundColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle;
        text = 'อนุมัติแล้ว';
        break;

      case 'pending':
        backgroundColor = const Color(0xFFFFF3E0);
        foregroundColor = const Color(0xFFEF6C00);
        icon = Icons.schedule;
        text = 'รอตรวจสอบ';
        break;

      case 'rejected':
        backgroundColor = const Color(0xFFFFEBEE);
        foregroundColor = const Color(0xFFC62828);
        icon = Icons.cancel;
        text = 'ไม่ผ่านการตรวจสอบ';
        break;

      default:
        backgroundColor = const Color(0xFFF5F5F5);
        foregroundColor = const Color(0xFF616161);
        icon = Icons.radio_button_unchecked;
        text = 'ยังไม่ได้ส่งเอกสาร';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: foregroundColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}