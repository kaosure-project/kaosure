import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/business/data/datasources/remote/business_registration_remote_data_source.dart';
import 'package:kaosure/features/kao_id/business/data/models/business_registration_model.dart';
import 'package:kaosure/features/kao_id/business/data/repositories/business_registration_repository_impl.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_document_file.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_document_kind.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_registration_failure.dart';
import 'package:kaosure/features/kao_id/business/domain/validators/business_registration_rules.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'business_registration_fakes.dart';

final class RecordingRemote implements BusinessRegistrationRemoteDataSource {
  String? userId = ownerId;
  String? uploadedPath;
  String? uploadedType;
  Map<String, String>? attached;
  bool? declared;
  Object? submitError;

  @override
  String? currentUserId() => userId;

  @override
  Future<void> uploadDocumentFile({required String path, required Uint8List bytes, required String contentType}) async {
    uploadedPath = path;
    uploadedType = contentType;
  }

  @override
  Future<BusinessRegistrationModel> attachDocument({
    required String registrationId,
    required BusinessDocumentKind kind,
    required String documentId,
    required String path,
    required String fileName,
  }) async {
    attached = {
      'registrationId': registrationId,
      'kind': kind.name,
      'documentId': documentId,
      'path': path,
      'fileName': fileName,
    };
    return BusinessRegistrationModel.fromEntity(draft(documentId: documentId));
  }

  @override
  Future<BusinessRegistrationModel> submit(String registrationId, {required bool directorDeclared}) async {
    declared = directorDeclared;
    final error = submitError;
    if (error != null) throw error;
    return BusinessRegistrationModel.fromEntity(draft());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late RecordingRemote remote;
  late BusinessRegistrationRepositoryImpl repository;

  setUp(() {
    remote = RecordingRemote();
    repository = BusinessRegistrationRepositoryImpl(remoteDataSource: remote, newId: () => 'doc-42');
  });

  test('uploads into the owner folder and attaches through the server', () async {
    final jpeg = BusinessDocumentFile(
      name: 'scan.JPEG',
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
      extension: 'JPEG',
    );
    final result = await repository.attachDocument(registrationId: 'reg-1', kind: BusinessDocumentKind.vat, file: jpeg);
    expect(remote.uploadedPath, '$ownerId/business-registration/reg-1/doc-42.jpg');
    expect(remote.uploadedType, 'image/jpeg');
    expect(remote.attached, {
      'registrationId': 'reg-1',
      'kind': 'vat',
      'documentId': 'doc-42',
      'path': '$ownerId/business-registration/reg-1/doc-42.jpg',
      'fileName': 'scan.JPEG',
    });
    expect(result.documentId, 'doc-42');
  });

  test('rejects files whose content does not match the extension', () async {
    final fake = BusinessDocumentFile(
      name: 'invoice.pdf',
      bytes: Uint8List.fromList([0x4D, 0x5A, 0x90, 0x00]),
      extension: 'pdf',
    );
    await expectLater(
      repository.attachDocument(registrationId: 'reg-1', kind: BusinessDocumentKind.certificate, file: fake),
      throwsA(
        isA<BusinessRegistrationFailure>().having((f) => f.code, 'code', BusinessRegistrationFailureCode.invalidFile),
      ),
    );
    expect(remote.uploadedPath, isNull);
  });

  test('rejects oversized files before upload', () async {
    final big = BusinessDocumentFile(
      name: 'big.pdf',
      bytes: Uint8List(BusinessDocumentFile.maxBytes + 1)..setAll(0, [0x25, 0x50, 0x44, 0x46]),
      extension: 'pdf',
    );
    expect(big.isAcceptable, isFalse);
    expect(pdfFile().isAcceptable, isTrue);
  });

  test('requires a signed-in owner before uploading', () async {
    remote.userId = null;
    await expectLater(
      repository.attachDocument(registrationId: 'reg-1', kind: BusinessDocumentKind.certificate, file: pdfFile()),
      throwsA(
        isA<BusinessRegistrationFailure>().having((f) => f.code, 'code', BusinessRegistrationFailureCode.session),
      ),
    );
    expect(remote.uploadedPath, isNull);
  });

  test('submit requires the director declaration before calling the server', () async {
    await expectLater(
      repository.submit('reg-1', directorDeclared: false),
      throwsA(
        isA<BusinessRegistrationFailure>().having(
          (f) => f.code,
          'code',
          BusinessRegistrationFailureCode.declarationRequired,
        ),
      ),
    );
    expect(remote.declared, isNull);

    await repository.submit('reg-1', directorDeclared: true);
    expect(remote.declared, isTrue);
  });

  test('maps the server certificate and Kao ID rules to typed failures', () async {
    for (final (message, code) in [
      ('certificate_too_old', BusinessRegistrationFailureCode.certificateTooOld),
      ('CERTIFICATE_DATE_REQUIRED', BusinessRegistrationFailureCode.certificateDateRequired),
      ('DIRECTOR_DECLARATION_REQUIRED', BusinessRegistrationFailureCode.declarationRequired),
      ('KAO_ID_REQUIRED', BusinessRegistrationFailureCode.kaoIdRequired),
      ('invalid_registration_number', BusinessRegistrationFailureCode.invalidNumber),
    ]) {
      remote.submitError = PostgrestException(message: message);
      await expectLater(
        repository.submit('reg-1', directorDeclared: true),
        throwsA(isA<BusinessRegistrationFailure>().having((f) => f.code, 'code', code)),
      );
    }
  });

  test('client rules mirror the server checks', () {
    expect(BusinessRegistrationRules.isValidJuristicNumber(validJuristicNumber), isTrue);
    expect(BusinessRegistrationRules.isValidJuristicNumber('0105561234567'), isFalse);
    expect(BusinessRegistrationRules.isValidJuristicNumber('010556123456'), isFalse);
    expect(BusinessRegistrationRules.isValidLegalNameEn(''), isTrue);
    expect(BusinessRegistrationRules.isValidLegalNameEn("KAO (THAILAND) CO., LTD."), isTrue);
    expect(BusinessRegistrationRules.isValidLegalNameEn('บริษัท'), isFalse);
    expect(BusinessRegistrationRules.oldestCertificateDate(DateTime(2026, 8, 31)), DateTime(2026, 2, 28));
    expect(BusinessRegistrationRules.oldestCertificateDate(DateTime(2026, 3, 15)), DateTime(2025, 9, 15));
    final today = DateTime(2026, 10, 13);
    expect(BusinessRegistrationRules.isCertificateDateAccepted(DateTime(2026, 4, 13), today), isTrue);
    expect(BusinessRegistrationRules.isCertificateDateAccepted(DateTime(2026, 4, 12), today), isFalse);
    expect(BusinessRegistrationRules.isCertificateDateAccepted(DateTime(2026, 10, 14), today), isFalse);
  });
}
