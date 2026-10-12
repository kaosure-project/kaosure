import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/kyc/review/kyc_review_repository.dart';
import 'package:kaosure/features/kao_id/kyc/review/kyc_review_page.dart';
import 'package:kaosure/features/kao_id/kyc/review/kao_id_issuance_card.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;

class ReviewFixture implements KycReviewRepository {
  bool denied = false;
  bool failIssue = false;
  int issues = 0;
  Map<String, dynamic>? identity;
  @override
  Future<bool> canReview() async => !denied;
  @override
  Future<List<Map<String, dynamic>>> queue() async {
    if (denied) { throw StateError('private-denial'); }
    return [];
  }
  @override
  Future<Uint8List> preview(String path) async => throw StateError('private-preview');
  @override
  Future<void> decide(String request, bool approve, String reason) async {}
  @override
  Future<Map<String, dynamic>?> myIdentity() async => identity;
  @override
  Future<String> issue() async {
    issues++;
    if (failIssue) { throw StateError('private-issue'); }
    identity = {'kao_id': 'KTESTONLY01', 'status': 'active'};
    return 'KTESTONLY01';
  }
}
Widget app(ReviewFixture repo, String language, Widget page) => ProviderScope(
  overrides: [
    authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
    kycReviewRepositoryProvider.overrideWithValue(repo),
  ], child: MaterialApp(locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: page));

void main() {
  for (final language in ['th','en']) {
    testWidgets('Denied review is an error, not an empty queue: $language', (tester) async {
      await tester.pumpWidget(app(ReviewFixture()..denied=true, language, const KycReviewPage()));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(KycReviewPage)));
      expect(find.text(l.reviewLoadFailed), findsOneWidget);
      expect(find.text(l.reviewEmpty), findsNothing);
      expect(find.textContaining('private-denial'), findsNothing);
    });
    testWidgets('Approval disabled before document inspection: $language', (tester) async {
      await tester.pumpWidget(app(ReviewFixture(), language, const KycReviewDetailPage(row: {
        'id':'request', 'full_name':'Example', 'document_number':'0000000000000',
        'paths':['owner/national-id/doc/front.jpg','owner/national-id/doc/back.jpg'],
      })));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(KycReviewDetailPage)));
      final button = find.widgetWithText(FilledButton,l.reviewApprove);
      await tester.scrollUntilVisible(button,150,scrollable:find.byType(Scrollable).first);
      expect(tester.widget<FilledButton>(button).onPressed,isNull);
    });
    testWidgets('Unapproved user has no issuance button: $language', (tester) async {
      final repo=ReviewFixture();
      await tester.pumpWidget(app(repo,language,const Scaffold(body: KaoIdIssuanceCard(eligible:false))));
      await tester.pumpAndSettle();
      final l=AppLocalizations.of(tester.element(find.byType(KaoIdIssuanceCard)));
      expect(find.text(l.issueRequest),findsNothing);
      expect(repo.issues,0);
    });
    testWidgets('Server issuance failure never displays a fabricated ID: $language', (tester) async {
      final repo=ReviewFixture()..failIssue=true;
      await tester.pumpWidget(app(repo,language,const Scaffold(body: KaoIdIssuanceCard(eligible:true))));
      await tester.pumpAndSettle();
      final l=AppLocalizations.of(tester.element(find.byType(KaoIdIssuanceCard)));
      await tester.tap(find.text(l.issueRequest));
      await tester.pumpAndSettle();
      expect(find.text(l.issueFailed),findsOneWidget);
      expect(find.text('KTESTONLY01'),findsNothing);
      expect(repo.issues,1);
    });
  }
}
