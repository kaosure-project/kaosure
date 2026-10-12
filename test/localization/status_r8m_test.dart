import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/kyc/data/models/verification_timeline.dart';
import 'package:kaosure/features/kao_id/kyc/application/states/kyc_state.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/kyc_identity_document.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/widgets/document_status_label.dart';
import 'package:kaosure/l10n/app_localizations.dart';

void main() {
  test('No records or confirmation timestamps means no invented history', () {
    expect(verificationTimeline(logs: [], requests: [], banks: []), isEmpty);
  });
  test('Confirmed email and submission preserve actual timestamps and order', () {
    final rows = verificationTimeline(logs: [], banks: [],
      emailConfirmedAt: '2026-09-20T10:00:00Z', requests: [
        {'id': 'request', 'created_at': '2026-09-21T10:00:00Z',
         'identity_documents': {'document_type': 'thai_national_id'}},
      ]);
    expect(rows.length, 2);
    expect(rows.first.action, 'submit:thai_national_id');
    expect(rows.first.newStatus, 'pending');
    expect(rows.last.action, 'email_confirmed');
    expect(rows.last.createdAt, DateTime.utc(2026, 9, 20, 10));
  });
  test('Existing submission log prevents duplicate request event', () {
    final rows = verificationTimeline(banks: [], logs: [
      {'id': 'log', 'verification_request_id': 'request', 'action': 'submit',
       'old_status': null, 'new_status': 'pending', 'performed_by': null,
       'notes': null, 'created_at': '2026-09-21T10:00:00Z'},
    ], requests: [
      {'id': 'request', 'created_at': '2026-09-21T10:00:00Z'},
    ]);
    expect(rows.length, 1);
    expect(rows.single.id, 'log');
  });
  test('Bank creation never fabricates an approval event', () {
    final rows = verificationTimeline(logs: [], requests: [], banks: [
      {'id': 'bank', 'created_at': '2026-09-21T10:00:00Z', 'status': 'approved'},
    ]);
    expect(rows.single.action, 'submit:bank');
    expect(rows.single.newStatus, 'pending');
  });
  for (final locale in AppLocalizations.supportedLocales) {
    test('Document existence and loading are distinct in $locale', () async {
      final l = await AppLocalizations.delegate.load(locale);
      final state = KycState.initial().copyWith(
        loadedResources: {KycResource.documents});
      expect(documentStatusLabel(l, state, null), l.kycNoDocumentSubmitted);
      expect(documentStatusLabel(l, KycState.initial(), null), l.kycUnknownStatus);
      expect(documentStatusLabel(l, state.copyWith(
        failedResources: {KycResource.documents}), null), l.kycUnknownStatus);
      final document = KycIdentityDocument(id: 'id', ownerId: 'owner',
        documentType: 'thai_national_id', documentNumber: '', status: 'pending_review',
        issuedDate: null, expiryDate: null, createdAt: DateTime(2026), updatedAt: DateTime(2026));
      expect(documentStatusLabel(l, state, document), l.kycPendingStatus);
      expect(documentStatusLabel(l, state, state.passport), l.kycNoDocumentSubmitted);
    });
  }
}
