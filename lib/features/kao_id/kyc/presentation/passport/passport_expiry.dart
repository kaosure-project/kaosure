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

    final expiry = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return expiry.isBefore(today);
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

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final lastDate = DateTime(
      now.year + 20,
      12,
      31,
    );

    DateTime selectedDate = initialDate ?? today;

    if (selectedDate.isBefore(today)) {
      selectedDate = today;
    }

    if (selectedDate.isAfter(lastDate)) {
      selectedDate = lastDate;
    }

    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: today,
      lastDate: lastDate,
      helpText: 'เลือกวันหมดอายุหนังสือเดินทาง',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือก',
    );

    if (result == null) {
      return null;
    }

    return PassportExpiry(
      date: result,
    );
  }
}