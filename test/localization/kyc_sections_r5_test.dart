import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/application/providers/account_providers.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_provider.dart';
import 'package:kaosure/features/kao_id/kyc/application/states/kyc_state.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/bank_verification.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/kyc_identity_document.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/verification.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/verification_history.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/verification_request.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/kyc_repository.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/screens/kyc_page.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/screens/verification_history_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'account_navigation_r3_test.dart' show FailingProfileRepository;
import 'auth_localization_r2_test.dart' show TestAuthNotifier;

final verification = Verification(
  id: 'verification-test', profileId: 'profile-test', accountLevel: 'registered',
  status: 'not_started', emailVerified: true, phoneVerified: false,
  identityCardStatus: 'not_started', passportStatus: 'not_started',
  residencePermitStatus: 'not_started', bankStatus: 'not_started',
  identityExpiry: null, passportExpiry: null, residencePermitExpiry: null,
  identityScore: 0, lastVerifiedAt: null, lastReviewedBy: null,
  rejectedReason: null, createdAt: DateTime(2026), updatedAt: DateTime(2026),
);

class KycFixture implements KycRepository {
  final failures = <KycResource>{};
  Completer<Verification>? gate;
  VerificationRequest? request;
  int submissions = 0;
  void check(KycResource resource) {
    if (failures.contains(resource)) throw StateError('private-test-error');
  }
  @override
  Future<Verification> getVerification() async {
    check(KycResource.verification);
    return gate == null ? verification : await gate!.future;
  }
  @override
  Future<VerificationRequest?> getVerificationRequest() async {
    check(KycResource.request); return request;
  }
  @override
  Future<List<KycIdentityDocument>> getIdentityDocuments() async {
    check(KycResource.documents); return [];
  }
  @override
  Future<BankVerification?> getBankVerification() async {
    check(KycResource.bank); return null;
  }
  @override
  Future<List<VerificationHistory>> getVerificationHistory() async {
    check(KycResource.history); return [];
  }
  @override
  Future<void> submitVerificationRequest({required String documentId}) async {
    submissions++;
  }
}

void main() {
  test('Optional failure preserves core data; retry clears failure', () async {
    final repository = KycFixture()..failures.add(KycResource.history);
    final container = ProviderContainer(overrides: [
      kycRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final controller = container.read(kycControllerProvider.notifier);
    await controller.load();
    var state = container.read(kycControllerProvider);
    expect(state.verification, verification);
    expect(state.isAvailable(KycResource.verification), isTrue);
    expect(state.isAvailable(KycResource.history), isFalse);
    expect(state.failedResources, {KycResource.history});
    expect(state.canSubmitVerificationRequest, isTrue);
    repository.failures.clear();
    await controller.load();
    state = container.read(kycControllerProvider);
    expect(state.hasError, isFalse);
    expect(state.isAvailable(KycResource.history), isTrue);
  });

  test('Unknown request state cannot submit; null reload clears stale request', () async {
    final repository = KycFixture();
    final container = ProviderContainer(overrides: [kycRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    final controller = container.read(kycControllerProvider.notifier);
    expect(container.read(kycControllerProvider).canSubmitVerificationRequest, isFalse);
    repository.request = VerificationRequest(id: 'request', requestedBy: 'profile-test',
      status: 'pending', reviewedAt: null, reviewedBy: null, rejectionReason: null,
      notes: null, createdAt: DateTime(2026), updatedAt: DateTime(2026));
    await controller.load();
    expect(container.read(kycControllerProvider).canSubmitVerificationRequest, isFalse);
    repository.request = null;
    await controller.load();
    expect(container.read(kycControllerProvider).verificationRequest, isNull);
    repository.failures.add(KycResource.request);
    await controller.load();
    await controller.submitVerificationRequest(documentId: 'test-document');
    expect(repository.submissions, 0);
  });

  test('Clear invalidates an in-flight response', () async {
    final repository = KycFixture()..gate = Completer<Verification>();
    final container = ProviderContainer(overrides: [kycRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    final controller = container.read(kycControllerProvider.notifier);
    final pending = controller.load();
    controller.clear();
    repository.gate!.complete(verification);
    await pending;
    expect(container.read(kycControllerProvider).verification, isNull);
    expect(container.read(kycControllerProvider).loadedResources, isEmpty);
  });

  for (final language in ['th', 'en']) {
    testWidgets('Failed KYC keeps menus and history retry at 320px: $language', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = KycFixture()..failures.addAll(KycResource.values);
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        profileRepositoryProvider.overrideWithValue(FailingProfileRepository()),
        kycRepositoryProvider.overrideWithValue(repository),
      ], child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const KycPage(),
      )));
      await tester.pumpAndSettle();
      for (final id in ['email', 'phone', 'identity-card', 'passport', 'history']) {
        final tile = find.byKey(ValueKey('kyc-$id'));
        await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable));
        await tester.pumpAndSettle();
        expect(tile.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('kyc-history')));
      await tester.pumpAndSettle();
      expect(find.byType(VerificationHistoryPage), findsOneWidget);
      expect(find.text(language == 'th'
          ? 'ยังไม่มีประวัติการยืนยันตัวตน' : 'No verification history yet.'), findsNothing);
      expect(find.textContaining('private-test-error'), findsNothing);
      repository.failures.remove(KycResource.history);
      final retry = find.byType(FilledButton);
      await tester.scrollUntilVisible(retry, 150,
        scrollable: find.descendant(of: find.byType(VerificationHistoryPage), matching: find.byType(Scrollable)));
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text(language == 'th'
          ? 'ยังไม่มีประวัติการยืนยันตัวตน' : 'No verification history yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
