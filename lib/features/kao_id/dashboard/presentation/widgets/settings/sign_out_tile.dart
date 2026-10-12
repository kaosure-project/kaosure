import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'sign_out_action.dart';

final class SignOutTile extends StatefulWidget {
  const SignOutTile({super.key});

  @override
  State<SignOutTile> createState() => _SignOutTileState();
}

final class _SignOutTileState extends State<SignOutTile> {
  bool _busy = false;
  bool _confirming = false;

  Future<void> _signOut() async {
    if (_busy || _confirming) return;
    setState(() => _confirming = true);
    final confirmed = await confirmSignOut(context);
    if (!mounted) return;
    if (!confirmed) {
      setState(() => _confirming = false);
      return;
    }
    setState(() {
      _confirming = false;
      _busy = true;
    });
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      enabled: !_busy && !_confirming,
      leading: const Icon(Icons.logout),
      title: Text(l10n.signOut),
      trailing: _busy
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _busy || _confirming ? null : _signOut,
    );
  }
}
