import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/business/data/datasources/remote/business_organization_remote_data_source.dart';
import 'package:kaosure/features/kao_id/business/data/repositories/business_organization_repository_impl.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_organization.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/organization_bank_draft.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_organization_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class RecordingOrganizationRemote implements BusinessOrganizationRemoteDataSource {
  String? user = 'owner-1';
  Object? uploadError;
  Object? submitError;
  Uint8List? stored;
  final uploads = <String>[];
  Map<String, String>? submitted;

  @override
  String? currentUserId() => user;

  @override
  Future<List<Map<String, dynamic>>> myOrganizations() async => [
    {
      'organization_id': 'org-1',
      'name': 'Kao Trading',
      'role': 'owner',
      'legal_name': 'บริษัท เก้า เทรดดิ้ง จำกัด',
      'legal_name_en': 'KAO TRADING CO., LTD.',
      'registration_number': '0105561234560',
      'verification_status': 'verified',
      'business_kao_id': 'KBZ12AB34CD',
      'kao_id_status': 'active',
      'can_manage_bank': true,
      'bank_verified': false,
      'banks': [
        {
          'id': 'b-2',
          'bank_name': 'SCB',
          'account_name': 'x',
          'last4': '1111',
          'status': 'rejected',
          'reason': 'Name mismatch',
        },
        {'id': 'b-1', 'bank_name': 'KBank', 'account_name': 'y', 'last4': '2222', 'status': 'verified'},
        'not a row',
      ],
      'shop': {'name': 'Kao Shop'},
    },
  ];

  @override
  Future<void> uploadEvidence({required String path, required Uint8List bytes}) async {
    uploads.add(path);
    final error = uploadError;
    if (error != null) throw error;
    stored = bytes;
  }

  @override
  Future<Uint8List?> downloadEvidence(String path) async => stored;

  @override
  Future<void> submitBank({
    required String organizationId,
    required String id,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String branch,
    required String type,
    required String evidencePath,
  }) async {
    final error = submitError;
    if (error != null) throw error;
    submitted = {
      'organizationId': organizationId,
      'id': id,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'branch': branch,
      'type': type,
      'evidencePath': evidencePath,
    };
  }
}

OrganizationBankDraft bankDraft({Uint8List? evidence}) => OrganizationBankDraft(
  id: 'bank-9',
  organizationId: 'org-1',
  bankName: ' Kasikorn Bank ',
  accountName: ' บริษัท เก้า เทรดดิ้ง จำกัด ',
  accountNumber: ' 1234567890 ',
  branch: '',
  type: OrganizationBankAccountType.current,
  evidenceJpeg: evidence ?? Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
);

void main() {
  late RecordingOrganizationRemote remote;
  late BusinessOrganizationRepositoryImpl repository;

  setUp(() {
    remote = RecordingOrganizationRemote();
    repository = BusinessOrganizationRepositoryImpl(remoteDataSource: remote);
  });

  Future<BusinessOrganizationFailureCode?> failureOf(Future<Object?> Function() run) async {
    try {
      await run();
      return null;
    } on BusinessOrganizationFailure catch (failure) {
      return failure.code;
    }
  }

  test('organization rows map to companies and skip malformed banks', () async {
    final company = (await repository.myOrganizations()).single;
    expect(company.legalNameEn, 'KAO TRADING CO., LTD.');
    expect(company.hasBusinessKaoId, isTrue);
    expect(company.banks.map((b) => b.status), [OrganizationBankStatus.rejected, OrganizationBankStatus.approved]);
    expect(company.banks.first.reason, 'Name mismatch');
    expect(company.hasPendingBank, isFalse);
    expect(company.canSubmitBank, isTrue);
    expect(company.shopName, 'Kao Shop');
  });

  test('bank evidence goes to the owner folder and the trimmed form reaches the server', () async {
    await repository.submitBank(bankDraft());
    expect(remote.uploads.single, 'owner-1/business-bank/bank-9/evidence.jpg');
    expect(remote.submitted, {
      'organizationId': 'org-1',
      'id': 'bank-9',
      'bankName': 'Kasikorn Bank',
      'accountName': 'บริษัท เก้า เทรดดิ้ง จำกัด',
      'accountNumber': '1234567890',
      'branch': '',
      'type': 'current',
      'evidencePath': 'owner-1/business-bank/bank-9/evidence.jpg',
    });
  });

  test('a retry accepts its own earlier upload but not a different file', () async {
    final draft = bankDraft();
    remote
      ..stored = draft.evidenceJpeg
      ..uploadError = const StorageException('The resource already exists');
    await repository.submitBank(draft);
    expect(remote.submitted, isNotNull);

    remote
      ..submitted = null
      ..stored = Uint8List.fromList([1, 2, 3]);
    expect(await failureOf(() => repository.submitBank(draft)), BusinessOrganizationFailureCode.uploadFailed);
    expect(remote.submitted, isNull);
  });

  test('missing session or empty evidence never uploads', () async {
    expect(
      await failureOf(() => repository.submitBank(bankDraft(evidence: Uint8List(0)))),
      BusinessOrganizationFailureCode.invalidEvidence,
    );
    remote.user = null;
    expect(await failureOf(() => repository.submitBank(bankDraft())), BusinessOrganizationFailureCode.session);
    expect(remote.uploads, isEmpty);
  });

  test('server rules map to typed failures', () async {
    for (final (message, code) in [
      ('bank_name_mismatch', BusinessOrganizationFailureCode.nameMismatch),
      ('bank_review_active', BusinessOrganizationFailureCode.reviewActive),
      ('business_kao_id_required', BusinessOrganizationFailureCode.businessKaoIdRequired),
      ('org_role_required', BusinessOrganizationFailureCode.roleRequired),
      ('something private', BusinessOrganizationFailureCode.unknown),
    ]) {
      remote.submitError = PostgrestException(message: message);
      expect(await failureOf(() => repository.submitBank(bankDraft())), code, reason: message);
    }
  });
}
