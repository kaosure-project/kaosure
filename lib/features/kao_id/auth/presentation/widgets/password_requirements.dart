import 'package:flutter/material.dart';

class PasswordRequirements extends StatelessWidget {
  final String password;

  const PasswordRequirements({
    super.key,
    required this.password,
  });

  /// อย่างน้อย 8 ตัวอักษร
  bool get _hasMinLength => password.runes.length >= 8;

  /// มีตัวเลข
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(password);

  /// มีอักขระพิเศษ
  bool get _hasSpecial =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~`]').hasMatch(password);

  /// มีตัวอักษร (รองรับทุกภาษา)
  bool get _hasLetter {
    for (final rune in password.runes) {
      final char = String.fromCharCode(rune);

      // ถ้าไม่ใช่ตัวเลข ไม่ใช่ช่องว่าง และไม่ใช่อักขระพิเศษ
      if (!RegExp(r'[0-9]').hasMatch(char) &&
          !RegExp(r'\s').hasMatch(char) &&
          !RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~`]').hasMatch(char)) {
        return true;
      }
    }

    return false;
  }

  Widget _item(bool passed, String text) {
    return Text(
      '${passed ? "✓" : "○"} $text',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: passed ? Colors.green : Colors.black54,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'รหัสผ่านต้องมี:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        _item(_hasMinLength, '8 ตัวขึ้นไป'),

        const Text(
          '•',
          style: TextStyle(
            color: Colors.black38,
          ),
        ),

        _item(_hasLetter, 'ตัวอักษร'),

        const Text(
          '•',
          style: TextStyle(
            color: Colors.black38,
          ),
        ),

        _item(_hasNumber, 'ตัวเลข'),

        const Text(
          '•',
          style: TextStyle(
            color: Colors.black38,
          ),
        ),

        _item(_hasSpecial, 'อักขระพิเศษ'),
      ],
    );
  }
}