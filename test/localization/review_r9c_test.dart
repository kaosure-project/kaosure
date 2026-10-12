import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/pages/review/kyc_review_page.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/utils/review_failure_message.dart';
import 'package:kaosure/features/kao_id/kyc/data/models/verification_timeline.dart';
import 'package:kaosure/l10n/app_localizations.dart';

void main() {
  test('Required evidence depends on document type and residence format', () {
    expect(requiredEvidenceCount({'document_type': 'thai_national_id'}), 2);
    expect(requiredEvidenceCount({'document_type': 'passport'}), 1);
    expect(requiredEvidenceCount({'document_type': 'bank'}), 1);
    expect(requiredEvidenceCount({'document_type': 'residence_card', 'residence_format': 'paper'}), 1);
    expect(requiredEvidenceCount({'document_type': 'residence_card', 'residence_format': 'card'}), 2);
    expect(requiredEvidenceCount({'document_type': 'unsupported'}), 0);
  });
  test('Bank approval uses recorded event time, not submission time', () {
    final rows = verificationTimeline(logs: [], requests: [], banks: [{
      'id': 'bank-test', 'created_at': '2026-09-01T10:00:00Z',
      'review_events': [{
        'id': 'event-test', 'action': 'kyc.bank.approve',
        'created_at': '2026-09-02T11:00:00Z', 'notes': 'Reviewed',
      }],
    }]);
    expect(rows.length, 2);
    expect(rows.first.action, 'approve:bank');
    expect(rows.first.createdAt, DateTime.utc(2026, 9, 2, 11));
    expect(rows.last.action, 'submit:bank');
    expect(rows.last.createdAt, DateTime.utc(2026, 9, 1, 10));
  });
  test('Current bank status alone does not manufacture approval history', () {
    final rows = verificationTimeline(logs: [], requests: [], banks: [{
      'id': 'bank-test', 'created_at': '2026-09-01T10:00:00Z',
      'status': 'verified', 'is_verified': true,
    }]);
    expect(rows.single.action, 'submit:bank');
  });
  test('Bank rejection preserves recorded reason', () {
    final rows = verificationTimeline(logs: [], requests: [], banks: [{
      'id': 'bank-test', 'created_at': '2026-09-01T10:00:00Z',
      'review_events': [{
        'id': 'event-test', 'action': 'kyc.bank.reject',
        'created_at': '2026-09-02T11:00:00Z', 'notes': 'Unreadable proof',
      }],
    }]);
    expect(rows.first.action, 'reject:bank');
    expect(rows.first.newStatus, 'rejected');
    expect(rows.first.notes, 'Unreadable proof');
  });
  for (final locale in const [Locale('th'), Locale('en'), Locale('ja'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale('my'), Locale('lo'), Locale('vi')]) {
    testWidgets('Review types and safe bank failure text: $locale', (tester) async {
      await tester.pumpWidget(MaterialApp(locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: SizedBox()),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(reviewTypeLabel(l, 'passport'), l.kycPassportTitle);
      expect(reviewTypeLabel(l, 'residence_card'), l.kycResidenceTitle);
      expect(reviewTypeLabel(l, 'bank'), l.kycBankTitle);
      expect(reviewFailureMessage(l,
        const PostgrestException(message: 'bank_verified_name_required'),
        l.reviewActionFailed), l.reviewBankNameRequired);
      expect(reviewFailureMessage(l,
        const PostgrestException(message: 'private bank account details'),
        l.reviewActionFailed), l.reviewActionFailed);
    });
  }
}
