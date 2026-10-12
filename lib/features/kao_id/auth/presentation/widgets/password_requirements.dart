import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

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
        Text(
          AppLocalizations.of(context).authRequirementsTitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        _item(_hasMinLength, AppLocalizations.of(context).authRequirementLength),

        const Text(
          '•',
          style: TextStyle(
            color: Colors.black38,
          ),
        ),

        _item(_hasNumber, AppLocalizations.of(context).authRequirementNumber),

        const Text(
          '•',
          style: TextStyle(
            color: Colors.black38,
          ),
        ),

        _item(_hasSpecial, AppLocalizations.of(context).authRequirementSpecial),
      ],
    );
  }
}