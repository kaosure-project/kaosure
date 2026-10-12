import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/application/providers/account_providers.dart';
import 'package:kaosure/features/kao_id/auth/application/notifiers/auth_notifier.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/auth/domain/entities/user_entity.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/verification.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/email/email_verification_page.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/screens/kyc_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'account_navigation_r3_test.dart' show FailingProfileRepository;
import 'kyc_sections_r5_test.dart' show KycFixture;

class EmailAuthFixture extends AuthNotifier {
  EmailAuthFixture(super.ref);
  bool confirmed = false;
  bool fail = false;
  @override
  Future<void> loadCurrentUser() async {
    state = const AsyncValue.data(null);
  }
  @override
  Future<UserEntity?> refreshCurrentUser() async {
    if (fail) {
      final error = StateError('test-only');
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }
    final user = UserEntity(id: 'owner', email: 'test@example.com',
      emailConfirmed: confirmed);
    state = AsyncValue.data(user);
    return user;
  }
}

class OppositeEmailKyc extends KycFixture {
  OppositeEmailKyc(this.email);
  final bool email;
  @override
  Future<Verification> getVerification() async => Verification(
    id: 'v', profileId: 'owner', accountLevel: 'registered', status: 'not_started',
    emailVerified: email, phoneVerified: false, identityCardStatus: 'not_started',
    passportStatus: 'not_started', residencePermitStatus: 'not_started',
    bankStatus: 'not_started', identityExpiry: null, passportExpiry: null,
    residencePermitExpiry: null, identityScore: 0, lastVerifiedAt: null,
    lastReviewedBy: null, rejectedReason: null,
    createdAt: DateTime(2026), updatedAt: DateTime(2026),
  );
}

void main() {
  for (final language in ['th', 'en']) {
    for (final confirmed in [true, false]) {
      testWidgets('Email hub/detail agree despite opposite KYC cache: $language $confirmed', (tester) async {
        await tester.pumpWidget(ProviderScope(overrides: [
          authProvider.overrideWith((ref) => EmailAuthFixture(ref)..confirmed = confirmed),
          profileRepositoryProvider.overrideWithValue(FailingProfileRepository()),
          kycRepositoryProvider.overrideWithValue(OppositeEmailKyc(!confirmed)),
        ], child: MaterialApp(locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const KycPage())));
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(tester.element(find.byType(KycPage)));
        final expected = confirmed ? l.kycVerifiedStatus : l.kycUnverifiedStatus;
        final tile = find.byKey(const ValueKey('kyc-email'));
        await tester.scrollUntilVisible(tile, 150, scrollable: find.byType(Scrollable).first);
        expect(tester.widget<ListTile>(tile).subtitle, isA<Text>().having((t) => t.data, 'status', expected));
        await Scrollable.ensureVisible(tester.element(tile), alignment: 0.5);
        await tester.pumpAndSettle();
        expect(tile.hitTestable(), findsOneWidget);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(find.byType(EmailVerificationPage), findsOneWidget);
        expect(find.text(expected), findsOneWidget);
        if (confirmed) {
          expect(find.text(l.authVerifyEmailInstructions), findsNothing);
          expect(find.text(l.authResendVerificationEmail), findsNothing);
        }
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(tester.widget<ListTile>(tile).subtitle, isA<Text>().having((t) => t.data, 'status', expected));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
    testWidgets('Email refresh failure shows unknown; retry recovers: $language', (tester) async {
      late EmailAuthFixture auth;
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => auth = EmailAuthFixture(ref)..fail = true),
      ], child: MaterialApp(locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const EmailVerificationPage())));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(EmailVerificationPage)));
      expect(find.text(l.kycUnknownStatus), findsOneWidget);
      expect(find.text(l.kycUnverifiedStatus), findsNothing);
      auth.fail = false;
      auth.confirmed = true;
      await tester.tap(find.text(l.authCheckAgain));
      await tester.pumpAndSettle();
      expect(find.text(l.kycVerifiedStatus), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
