import 'package:flutter/material.dart';

final class PassportExpiry {
  const PassportExpiry({
    required this.date,
  });

  final DateTime date;

  bool get isExpired {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return date.isBefore(today);
  }

  String get displayText {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static Future<PassportExpiry?> pick(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 20,
        12,
        31,
      ),
      helpText: 'เลือกวันหมดอายุหนังสือเดินทาง',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือก',
    );

    if (selected == null) {
      return null;
    }

    return PassportExpiry(
      date: selected,
    );
  }
}