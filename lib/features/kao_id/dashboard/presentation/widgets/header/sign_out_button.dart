import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../settings/sign_out_action.dart';
import 'header_action_button.dart';

class SignOutButton extends StatefulWidget {
  const SignOutButton({super.key, this.compact = false});

  final bool compact;

  @override
  State<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<SignOutButton> {
  bool _busy = false;

  Future<void> _signOut() async {
    if (_busy) return;
    final confirmed = await confirmSignOut(context);
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await signOutAndLeave(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signOutFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => HeaderActionButton(
        icon: Icons.logout,
        label: AppLocalizations.of(context).signOut,
        compact: widget.compact,
        busy: _busy,
        onPressed: _signOut,
      );
}
