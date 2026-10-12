import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../shared/design_system/colors/app_colors.dart';

/// Asks for the password and runs [unlock] (null result = success); resolves true once unlocked.
Future<bool> showRevealPasswordDialog(BuildContext context,
    {required Future<String?> Function(String password) unlock}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PasswordPromptDialog(unlock: unlock),
  );
  return result ?? false;
}

class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog({required this.unlock});

  final Future<String?> Function(String password) unlock;

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.unlock(_password.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = false;
      _error = switch (failure) {
        'password' => l10n.piPasswordWrong,
        'rate_limited' => l10n.piRateLimited,
        'session' => l10n.contactSessionChanged,
        _ => l10n.piRevealFailed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.lock_outline, color: AppColors.kaoBlue),
      title: Text(l10n.piPasswordTitle),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.piPasswordHelp, style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('reveal-password'),
            controller: _password,
            autofocus: true,
            obscureText: _obscure,
            enabled: !_busy,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.password,
              errorText: _error,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('reveal-confirm'),
          onPressed: _busy || _password.text.isEmpty ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.kaoBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(112, 44),
          ),
          child: _busy
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.piPasswordConfirm),
        ),
      ],
    );
  }
}
