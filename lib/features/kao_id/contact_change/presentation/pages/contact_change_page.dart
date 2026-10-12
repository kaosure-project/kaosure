import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../application/controllers/contact_change_controller.dart';
import '../../domain/entities/contact_snapshot.dart';
import '../../data/repositories/supabase_contact_change_repository.dart';

class ContactChangePage extends ConsumerStatefulWidget {
  const ContactChangePage({super.key, required this.kind});
  final ContactKind kind;
  @override
  ConsumerState<ContactChangePage> createState() => _ContactChangePageState();
}

class _ContactChangePageState extends ConsumerState<ContactChangePage> {
  final _target = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  final _mfa = TextEditingController();
  late final ContactChangeController _controller;
  Timer? _timer;
  String? _factor;

  @override
  void initState() {
    super.initState();
    _controller = ContactChangeController(
      ref.read(contactChangeRepositoryProvider), widget.kind);
    _controller.addListener(_changed);
    Future.microtask(() async {
      await _controller.refresh();
      if (mounted) _target.text = _controller.pending;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _changed());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_changed);
    _controller.dispose();
    _target.dispose();
    _password.dispose();
    _otp.dispose();
    _mfa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _controller;
    final email = widget.kind == ContactKind.email;
    final wait = c.retryAt?.difference(DateTime.now()).inSeconds ?? 0;
    final factors = c.snapshot?.factorIds ?? const <String>[];
    final message = switch (c.message) {
      'done' => l.changeContactDone,
      'sent' || 'pending' => email ? l.changeEmailPending : l.contactStillPending,
      'same' => l.changeContactSame,
      'invalid' => email ? l.changeEmailInvalid : l.contactPhoneInvalid,
      'password' => l.changeContactPasswordRequired,
      'mfa' => l.changeContactMfaRequired,
      'session' => l.contactSessionChanged,
      'otp' => l.contactOtpInvalid,
      'verify' => l.contactOtpFailed,
      'load' => l.contactLoadFailed,
      _ => l.changeContactFailed,
    };
    return Scaffold(
      appBar: AppBar(title: Text(email ? l.changeEmailTitle : l.changePhoneTitle)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.changeContactIntro),
          const SizedBox(height: 16),
          Text(l.changeContactCurrent, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(c.known ? (c.snapshot?.value.isNotEmpty == true
            ? c.snapshot!.value : '—') : l.kycUnknownStatus),
          const SizedBox(height: 16),
          if (c.pending.isNotEmpty) ...[
            Text('${l.changeContactPending}: ${c.pending}'),
            const SizedBox(height: 8),
            Text(email ? l.changeEmailPending : l.contactExpiryHelp),
            const SizedBox(height: 16),
          ],
          TextField(controller: _target, enabled: c.known && !c.busy,
            autocorrect: false, keyboardType: email ? TextInputType.emailAddress : TextInputType.phone,
            decoration: InputDecoration(labelText: email ? l.changeEmailNew : l.changePhoneNew,
              helperText: email ? null : l.contactPhoneFormat, helperMaxLines: 3,
              border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _password, enabled: c.known && !c.busy,
            obscureText: true, autocorrect: false, enableSuggestions: false,
            decoration: InputDecoration(labelText: l.changeContactPassword,
              border: const OutlineInputBorder())),
          const SizedBox(height: 8),
          Text(l.changeContactPasswordHelp),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: factors.contains(_factor) ? _factor : factors.first,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.changeContactMfaDevice),
              items: [for (var i = 0; i < factors.length; i++)
                DropdownMenuItem(value: factors[i], child: Text('${l.changeContactMfaDevice} ${i + 1}'))],
              onChanged: c.busy ? null : (value) => setState(() => _factor = value)),
            const SizedBox(height: 16),
            TextField(controller: _mfa, enabled: !c.busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: InputDecoration(labelText: l.changeContactMfaCode,
                border: const OutlineInputBorder())),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: c.canSend ? () async {
            final password = _password.text;
            final code = _mfa.text;
            _password.clear();
            _mfa.clear();
            await c.submit(_target.text, password,
              factorId: _factor ?? (factors.isEmpty ? null : factors.first), code: code);
          } : null, child: Text(wait > 0 ? '${l.contactWait} ($wait)' : l.changeContactRequest)),
          if (!email && c.pending.isNotEmpty) ...[
            const SizedBox(height: 20),
            TextField(controller: _otp, enabled: c.known && !c.busy,
              keyboardType: TextInputType.number, autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: InputDecoration(labelText: l.contactOtpLabel, border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            FilledButton(onPressed: c.busy || !c.known ? null : () async {
              final code = _otp.text;
              _otp.clear();
              await c.verify(code);
            }, child: Text(l.contactVerifyCode)),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: c.busy ? null : c.refresh,
            icon: const Icon(Icons.refresh), label: Text(l.authCheckAgain)),
          if (c.busy) ...[const SizedBox(height: 16), const LinearProgressIndicator()],
          if (c.message != null) ...[const SizedBox(height: 16),
            Semantics(liveRegion: true, child: Text(message))],
        ]),
      ))),
    );
  }
}
