import 'package:kaosure/l10n/app_localizations.dart';
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
      helpText: AppLocalizations.of(context).kycSelectPassportExpiryDate,
      cancelText: AppLocalizations.of(context).kycCancel,
      confirmText: AppLocalizations.of(context).kycSelect,
    );

    if (selected == null) {
      return null;
    }

    return PassportExpiry(
      date: selected,
    );
  }
}