import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/contact_change/application/controllers/contact_change_controller.dart';
import 'package:kaosure/features/kao_id/contact_change/domain/entities/contact_snapshot.dart';
import 'package:kaosure/features/kao_id/contact_change/domain/repositories/contact_change_repository.dart';
import 'package:kaosure/features/kao_id/contact_change/data/repositories/supabase_contact_change_repository.dart';
import 'package:kaosure/features/kao_id/contact_change/presentation/pages/contact_change_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class ChangeFixture implements ContactChangeRepository {
  ContactSnapshot value = const ContactSnapshot('a', 'old@example.com', true, '');
  int requests = 0;
  int verifies = 0;
  bool lastResend = false;
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<ContactSnapshot> read(ContactKind kind) async => value;
  @override
  Future<void> request(ContactKind kind, String owner, String target,
      String password, {required bool resend, String? factorId, String? code}) async {
    requests++;
    lastResend = resend;
    if (gate != null) await gate!.future;
    if (fail) throw StateError('private error');
    value = ContactSnapshot(owner, value.value, value.confirmed, target);
  }
  @override
  Future<void> verifyPhone(String owner, String target, String token) async {
    verifies++;
  }
}

void main() {
  test('Request keeps original contact and waits for authoritative confirmation', () async {
    final repository = ChangeFixture();
    final c = ContactChangeController(repository, ContactKind.email);
    addTearDown(c.dispose);
    await c.refresh();
    await c.submit('new@example.com', 'secret');
    expect(c.snapshot!.value, 'old@example.com');
    expect(c.pending, 'new@example.com');
    expect(c.message, isNot('done'));
    repository.value = const ContactSnapshot('a', 'new@example.com', true, '');
    await c.refresh();
    expect(c.pending, isEmpty);
    expect(c.message, 'done');
  });
  test('Cooldown blocks duplicates and resend uses pending target', () async {
    var now = DateTime(2026);
    final repository = ChangeFixture();
    final c = ContactChangeController(repository, ContactKind.email, clock: () => now);
    addTearDown(c.dispose);
    await c.refresh();
    await c.submit('new@example.com', 'secret');
    await c.submit('new@example.com', 'secret');
    expect(repository.requests, 1);
    now = now.add(const Duration(seconds: 61));
    await c.submit('new@example.com', 'secret');
    expect(repository.requests, 2);
    expect(repository.lastResend, isTrue);
  });
  test('Account switch blocks a pending request', () async {
    final repository = ChangeFixture();
    final c = ContactChangeController(repository, ContactKind.email);
    addTearDown(c.dispose);
    await c.refresh();
    repository.value = const ContactSnapshot('b', 'other@example.com', true, '');
    await c.submit('new@example.com', 'secret');
    expect(repository.requests, 0);
    expect(c.message, 'session');
    expect(c.known, isFalse);
  });
  test('Invalid, unchanged and missing-password input do not send', () async {
    final repository = ChangeFixture();
    final c = ContactChangeController(repository, ContactKind.email);
    addTearDown(c.dispose);
    await c.refresh();
    await c.submit('bad', 'secret');
    expect(c.message, 'invalid');
    await c.submit('old@example.com', 'secret');
    expect(c.message, 'same');
    await c.submit('new@example.com', '');
    expect(c.message, 'password');
    expect(repository.requests, 0);
  });
  test('Phone OTP response alone is not confirmation', () async {
    final repository = ChangeFixture()
      ..value = const ContactSnapshot('a', '+66811111111', true, '+66822222222');
    final c = ContactChangeController(repository, ContactKind.phone);
    addTearDown(c.dispose);
    await c.refresh();
    await c.verify('123456');
    expect(repository.verifies, 1);
    expect(c.pending, '+66822222222');
    expect(c.message, isNot('done'));
  });
  test('Transport error is safe and preserves cooldown', () async {
    final repository = ChangeFixture()..fail = true;
    final c = ContactChangeController(repository, ContactKind.email);
    addTearDown(c.dispose);
    await c.refresh();
    await c.submit('new@example.com', 'secret');
    expect(c.message, 'request');
    expect(c.canSend, isFalse);
  });
  test('Disposing in-flight request does not notify a disposed controller', () async {
    final repository = ChangeFixture()..gate = Completer<void>();
    final c = ContactChangeController(repository, ContactKind.email);
    await c.refresh();
    final pending = c.submit('new@example.com', 'secret');
    await Future<void>.delayed(Duration.zero);
    c.dispose();
    repository.gate!.complete();
    await pending;
  });
  for (final lang in ['th', 'en']) {
    for (final kind in ContactKind.values) {
      testWidgets('Change contact fits narrow screen $lang $kind', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(overrides: [
          contactChangeRepositoryProvider.overrideWithValue(ChangeFixture()),
        ], child: MaterialApp(
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
          home: ContactChangePage(kind: kind),
        )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('old@example.com'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
