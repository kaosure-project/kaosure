import 'dart:typed_data';

import 'package:kaosure/features/kao_id/business/domain/entities/business_document_file.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_registration.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/payout_bank_account.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_registration_failure.dart';
import 'package:kaosure/features/kao_id/business/domain/repositories/business_registration_repository.dart';

const ownerId = 'owner-1';

const approvedBank = PayoutBankAccount(
  status: PayoutBankStatus.approved,
  bankName: 'Kasikorn Bank',
  maskedNumber: 'xxx-x-x1234-x',
);

const pendingBank = PayoutBankAccount(
  status: PayoutBankStatus.pending,
  bankName: 'Kasikorn Bank',
  maskedNumber: 'xxx-x-x1234-x',
);

BusinessDocumentFile pdfFile([String name = 'certificate.pdf']) => BusinessDocumentFile(
      name: name,
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]),
      extension: 'pdf',
    );

BusinessRegistration draft({String? documentId, BusinessRegistrationStatus? status,
    DateTime? submittedAt}) =>
    BusinessRegistration(
      id: 'reg-1',
      userId: ownerId,
      businessType: 'registered_business',
      businessName: 'Kao Shop',
      registrationNumber: '0105561234567',
      businessCategory: 'retail',
      documentId: documentId,
      status: status ?? BusinessRegistrationStatus.draft,
      submittedAt: submittedAt,
    );

/// In-memory stand-in for the server: one registration per owner.
final class FakeBusinessRegistrationRepository implements BusinessRegistrationRepository {
  FakeBusinessRegistrationRepository({this.current, this.userId = ownerId});

  BusinessRegistration? current;
  String? userId;
  BusinessRegistrationFailureCode? failNext;
  final calls = <String>[];

  void _maybeFail() {
    final code = failNext;
    if (code != null) {
      failNext = null;
      throw BusinessRegistrationFailure(code);
    }
  }

  @override
  String? currentUserId() => userId;

  @override
  Future<BusinessRegistration?> getCurrent(String userId) async {
    calls.add('getCurrent');
    _maybeFail();
    return current;
  }

  @override
  Future<BusinessRegistration?> getById(String registrationId) async => current;

  @override
  Future<BusinessRegistration> createDraft(BusinessRegistration registration) async {
    calls.add('createDraft');
    _maybeFail();
    return current = registration.copyWith(id: 'reg-1');
  }

  @override
  Future<BusinessRegistration> updateDraft(BusinessRegistration registration) async {
    calls.add('updateDraft');
    _maybeFail();
    return current = registration;
  }

  @override
  Future<BusinessRegistration> attachDocument({
    required String registrationId,
    required BusinessDocumentFile file,
  }) async {
    calls.add('attachDocument:${file.name}');
    _maybeFail();
    return current = current!.copyWith(
      documentId: 'doc-1',
      documentStatus: BusinessDocumentStatus.uploaded,
    );
  }

  @override
  Future<BusinessRegistration> submit(String registrationId) async {
    calls.add('submit');
    _maybeFail();
    return current = current!.copyWith(
      status: BusinessRegistrationStatus.submitted,
      submittedAt: DateTime(2026, 10, 12),
    );
  }

  @override
  Future<BusinessRegistration> refreshStatus(String registrationId) async {
    calls.add('refreshStatus');
    return current!;
  }

  @override
  Future<void> cancelDraft(String registrationId) async {
    calls.add('cancelDraft');
    _maybeFail();
    current = null;
  }
}
