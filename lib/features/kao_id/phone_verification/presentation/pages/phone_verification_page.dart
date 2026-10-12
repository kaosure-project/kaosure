import 'package:kaosure/features/kao_id/contact_change/contact_change_page.dart';
import 'package:kaosure/features/kao_id/contact_change/contact_change_repository.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../providers/phone_verification_provider.dart';

final class PhoneVerificationPage extends ConsumerStatefulWidget {
  const PhoneVerificationPage({super.key});
  @override
  ConsumerState<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}
class _PhoneVerificationPageState extends ConsumerState<PhoneVerificationPage> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) { return; }
      await ref.read(phoneVerificationControllerProvider.notifier).load();
      if (mounted) _phone.text = ref.read(phoneVerificationControllerProvider).phoneNumber;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }
  @override
  void dispose() {
    _timer?.cancel(); _phone.dispose(); _otp.dispose(); super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(phoneVerificationControllerProvider);
    final controller = ref.read(phoneVerificationControllerProvider.notifier);
    final wait = s.retryAt?.difference(DateTime.now()).inSeconds ?? 0;
    final error = switch (s.errorMessage) {
      'phone' => l.contactPhoneInvalid,
      'otp' => l.contactOtpInvalid,
      'verify' => l.contactOtpFailed,
      'send' => l.contactSendFailed,
      'pending' => l.contactStillPending,
      'session' => l.contactSessionChanged,
      _ => l.contactLoadFailed,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.kycPhoneTitle)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.contactPhoneIntro), const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.phoneNumber.isEmpty ? l.contactNoPhone : s.phoneNumber),
              const SizedBox(height: 8),
              Text(!s.statusKnown ? l.kycUnknownStatus : s.isVerified
                ? l.kycVerifiedStatus : l.kycUnverifiedStatus),
              TextButton.icon(onPressed: s.isLoading ? null : controller.load,
                icon: const Icon(Icons.refresh), label: Text(l.authCheckAgain)),
            ],
          ))),
          const SizedBox(height: 20),
          if (s.statusKnown && s.isVerified) ...[
            OutlinedButton.icon(onPressed: s.isLoading ? null : () async {
              await Navigator.of(context).push<void>(MaterialPageRoute(
                builder: (_) => const ContactChangePage(kind: ContactKind.phone)));
              if (mounted) await controller.load();
            }, icon: const Icon(Icons.edit_outlined), label: Text(l.changePhoneTitle)),
          ] else ...[
          TextField(controller: _phone, enabled: !s.isLoading,
            keyboardType: TextInputType.phone, autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(labelText: l.kycPhoneTitle,
              helperText: l.contactPhoneFormat, helperMaxLines: 3,
              border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          FilledButton(onPressed: s.statusKnown && controller.canSend ? () async {
            _otp.clear();
            await controller.sendOtp(phoneNumber: _phone.text);
          } : null, child: Text(wait > 0 ? '${l.contactWait} ($wait)' : l.contactSendCode)),
          if (s.isOtpSent) ...[
            const SizedBox(height: 20),
            Text('${l.contactCodeDestination}: ${s.pendingPhone}'),
            const SizedBox(height: 12),
            TextField(controller: _otp, enabled: !s.isLoading,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: InputDecoration(labelText: l.contactOtpLabel,
                border: const OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(onPressed: s.isLoading ? null : () async {
              await controller.verifyOtp(otp: _otp.text);
              if (mounted && !ref.read(phoneVerificationControllerProvider).isOtpSent) _otp.clear();
            }, child: Text(l.contactVerifyCode)),
          ],
          ],
          if (s.isLoading) ...[const SizedBox(height: 16), const LinearProgressIndicator()],
          if (s.errorMessage != null) ...[
            const SizedBox(height: 16),
            Semantics(liveRegion: true, child: Text(error,
              style: TextStyle(color: Theme.of(context).colorScheme.error))),
          ],
          const SizedBox(height: 20), Text(l.contactExpiryHelp),
        ]),
      ))),
    );
  }
}
