import '../../../auth/application/providers/email_verification_status_provider.dart';
import 'package:kaosure/features/kao_id/contact_change/presentation/pages/contact_change_page.dart';
import 'package:kaosure/features/kao_id/contact_change/domain/entities/contact_snapshot.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../auth/application/providers/auth_provider.dart';

final class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});
  @override
  ConsumerState<EmailVerificationPage> createState() => _EmailVerificationPageState();
}
class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _busy = false;
  bool _known = false;
  String? _message;
  DateTime? _retryAt;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) { setState(() {}); }
    });
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _refresh() async {
    if (!mounted || _busy) { return; }
    setState(() { _busy = true; _message = null; });
    try {
      final user = await ref.read(authProvider.notifier).refreshCurrentUser();
      if (!mounted) { return; }
      setState(() { _known = user != null; _message = user == null ? 'error' : null; });
    } catch (_) {
      if (mounted) { setState(() { _known = false; _message = 'error'; }); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }

  Future<void> _send() async {
    if (_busy || (_retryAt != null && DateTime.now().isBefore(_retryAt!))) { return; }
    setState(() {
      _busy = true; _message = null;
      _retryAt = DateTime.now().add(const Duration(seconds: 60));
    });
    try {
      await ref.read(authProvider.notifier).resendEmailVerification();
      if (mounted) { setState(() => _message = 'sent'); }
    } catch (_) {
      if (mounted) { setState(() => _message = 'error'); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value;
    final emailStatus = ref.watch(emailVerificationStatusProvider);
    final verified = _known && emailStatus == true;
    final remaining = _retryAt?.difference(DateTime.now()).inSeconds ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(l.authVerifyEmail)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(verified ? l.authEmailVerified : l.authVerifyEmailInstructions), const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.email ?? '—'), const SizedBox(height: 12),
              Text(!_known || emailStatus == null ? l.kycUnknownStatus
                : verified ? l.kycVerifiedStatus : l.kycUnverifiedStatus),
            ],
          ))),
          const SizedBox(height: 20),
          if (!verified) FilledButton(
            onPressed: _busy || !_known || user == null || remaining > 0 ? null : _send,
            child: Text(remaining > 0 ? '${l.contactWait} ($remaining)'
              : l.authResendVerificationEmail)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh), label: Text(l.authCheckAgain)),
          if (_busy) ...[const SizedBox(height: 16), const LinearProgressIndicator()],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Semantics(liveRegion: true, child: Text(_message == 'sent'
              ? l.authVerificationEmailSent : l.authVerificationFailed)),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _busy || !_known || user == null ? null : () async {
              await Navigator.of(context).push<void>(MaterialPageRoute(
                builder: (_) => const ContactChangePage(kind: ContactKind.email)));
              if (mounted) { await _refresh(); }
            },
            icon: const Icon(Icons.edit_outlined), label: Text(l.changeEmailTitle)),
          if (!verified) ...[
            const SizedBox(height: 20), Text(l.contactEmailRefreshHelp),
          ],
        ]),
      ))),
    );
  }
}
