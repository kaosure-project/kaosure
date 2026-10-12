import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/kyc/review/kao_id_issuance_card.dart';
import 'package:kaosure/features/kao_id/kyc/review/kyc_review_page.dart';
import 'package:kaosure/features/kao_id/kyc/review/kyc_review_repository.dart';
import 'package:kaosure/features/kao_id/kyc/review/review_failure_message.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
import 'kyc_review_r7c_test.dart' show ReviewFixture;

class SessionFixture extends TestAuthNotifier {
  SessionFixture(super.ref);
  void signOutForTest() { state = const AsyncValue.data(null); }
}

class RefreshFixture extends ReviewFixture {
  Completer<Map<String, dynamic>?>? pending;
  @override
  Future<Map<String, dynamic>?> myIdentity() =>
      pending?.future ?? Future.value(identity);
}

void main() {
  for (final language in ['th', 'en']) {
    testWidgets('Review error whitelist hides backend details: $language', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: SizedBox()),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(reviewFailureMessage(l, const PostgrestException(message: 'reviewer_required'), l.reviewActionFailed), l.reviewNoPermission);
      expect(reviewFailureMessage(l, const PostgrestException(message: 'request_already_reviewed'), l.reviewActionFailed), l.reviewAlreadyDone);
      expect(reviewFailureMessage(l, const PostgrestException(message: 'private database details'), l.reviewActionFailed), l.reviewActionFailed);
    });
    testWidgets('Signing out hides reviewer document details: $language', (tester) async {
      late SessionFixture auth;
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => auth = SessionFixture(ref)),
        kycReviewRepositoryProvider.overrideWithValue(ReviewFixture()),
      ], child: MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const KycReviewDetailPage(row: {
          'id': 'example-request', 'full_name': 'Example private name',
          'document_number': '0000000000000', 'paths': <String>[],
        }),
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Example private name'), findsOneWidget);
      final l = AppLocalizations.of(tester.element(find.byType(KycReviewDetailPage)));
      auth.signOutForTest();
      await tester.pumpAndSettle();
      expect(find.textContaining('Example private name'), findsNothing);
      expect(find.textContaining('0000000000000'), findsNothing);
      expect(find.text(l.contactSessionChanged), findsOneWidget);
      expect(find.text(l.reviewApprove), findsNothing);
    });
    testWidgets('Refresh hides previous ID until current result arrives: $language', (tester) async {
      final repo = RefreshFixture()..identity = {'kao_id': 'KTESTONLY01', 'status': 'active'};
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        kycReviewRepositoryProvider.overrideWithValue(repo),
      ], child: MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: KaoIdIssuanceCard(eligible: false)),
      )));
      await tester.pumpAndSettle();
      expect(find.text('KTESTONLY01'), findsOneWidget);
      final l = AppLocalizations.of(tester.element(find.byType(KaoIdIssuanceCard)));
      repo.pending = Completer<Map<String, dynamic>?>();
      await tester.tap(find.text(l.authCheckAgain));
      await tester.pump();
      expect(find.text('KTESTONLY01'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      repo.pending!.complete(null);
      await tester.pumpAndSettle();
      expect(find.text(l.issueAwaitingReview), findsOneWidget);
    });
  }
}
