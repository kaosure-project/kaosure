import 'dart:typed_data';

import 'package:kaosure/features/kao_id/business/domain/entities/business_document_file.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_document_kind.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_registration.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_registration_failure.dart';
import 'package:kaosure/features/kao_id/business/domain/repositories/business_registration_repository.dart';

const ownerId = 'owner-1';

/// Passes the Thai juristic check digit.
const validJuristicNumber = '0105561234560';

final issuedOn = DateTime(2026, 9, 1);

BusinessDocumentFile pdfFile([String name = 'certificate.pdf']) =>
    BusinessDocumentFile(name: name, bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]), extension: 'pdf');

BusinessRegistration draft({
  String? documentId,
  String? vatDocumentId,
  BusinessRegistrationStatus? status,
  DateTime? submittedAt,
  DateTime? certificateIssuedOn,
  bool withCertificateDate = true,
}) => BusinessRegistration(
  id: 'reg-1',
  userId: ownerId,
  businessType: 'registered_business',
  businessName: 'Kao Shop',
  registrationNumber: validJuristicNumber,
  businessCategory: 'retail',
  certificateIssuedOn: withCertificateDate ? certificateIssuedOn ?? issuedOn : null,
  documentId: documentId,
  vatDocumentId: vatDocumentId,
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
    required BusinessDocumentKind kind,
    required BusinessDocumentFile file,
  }) async {
    calls.add('attachDocument:${kind.name}:${file.name}');
    _maybeFail();
    return current = switch (kind) {
      BusinessDocumentKind.certificate => current!.copyWith(
        documentId: 'doc-1',
        documentStatus: BusinessDocumentStatus.uploaded,
      ),
      BusinessDocumentKind.vat => current!.copyWith(vatDocumentId: 'vat-1'),
    };
  }

  @override
  Future<BusinessRegistration> removeVatDocument(String registrationId) async {
    calls.add('removeVatDocument');
    _maybeFail();
    final c = current!;
    return current = BusinessRegistration(
      id: c.id,
      userId: c.userId,
      businessType: c.businessType,
      businessName: c.businessName,
      registrationNumber: c.registrationNumber,
      businessCategory: c.businessCategory,
      certificateIssuedOn: c.certificateIssuedOn,
      documentId: c.documentId,
      documentStatus: c.documentStatus,
      status: c.status,
    );
  }

  @override
  Future<BusinessRegistration> submit(String registrationId, {required bool directorDeclared}) async {
    calls.add('submit:$directorDeclared');
    _maybeFail();
    return current = current!.copyWith(
      status: BusinessRegistrationStatus.submitted,
      submittedAt: DateTime(2026, 10, 12),
      directorDeclaredAt: DateTime(2026, 10, 12),
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
