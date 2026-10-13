import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/business/data/datasources/remote/business_review_remote_data_source.dart';
import 'package:kaosure/features/kao_id/business/data/repositories/business_review_repository_impl.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_review_outcome.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_review_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class RecordingReviewRemote implements BusinessReviewRemoteDataSource {
  String? user = 'reviewer';
  String status = 'approved';
  String link = 'https://storage.example/signed/doc.pdf';
  Object? error;
  final calls = <String>[];
  Map<String, Object?>? lastDecision;

  /// Simulates the session changing while a request is in flight.
  String? userAfterCall;

  @override
  String? currentUserId() => user;

  Future<T> _call<T>(String name, T value) async {
    calls.add(name);
    if (userAfterCall != null) user = userAfterCall;
    final failure = error;
    if (failure != null) throw failure;
    return value;
  }

  @override
  Future<List<Map<String, dynamic>>> queue() => _call('queue', [
    {
      'id': 'reg-1',
      'status': 'under_review',
      'submitted_at': '2026-10-12T03:00:00Z',
      'business_type': 'registered_business',
      'business_name': 'Kao Trading',
      'registration_number': '0105561234560',
      'registration_number_valid': true,
      'registration_number_taken': false,
      'legal_name_en': 'KAO TRADING CO., LTD.',
      'certificate_issued_on': '2026-09-01',
      'certificate_fresh': true,
      'business_category': 'retail',
      'business_description': '  ',
      'document_name': 'cert.pdf',
      'document_mime': 'application/pdf',
      'paths': ['a/business-registration/reg-1/doc.pdf', 42],
      'vat_document_name': 'vat.png',
      'vat_document_mime': 'image/png',
      'vat_paths': ['a/business-registration/reg-1/vat.png'],
      'owner_kao_id': 'KAB12CD34EF',
      'owner_name': null,
      'director_declared': true,
      'dual_review': true,
      'first_reviewer': 'other',
      'first_decision': false,
      'first_reason': 'Blurry',
    },
  ]);

  @override
  Future<Uint8List> download(String path) => _call('download', Uint8List(4));

  @override
  Future<String> signedUrl(String path) => _call('signedUrl', link);

  @override
  Future<String> decide({
    required String expectedUserId,
    required String registrationId,
    required bool approve,
    required bool directorConfirmed,
    String? reason,
  }) {
    lastDecision = {
      'expected': expectedUserId,
      'id': registrationId,
      'approve': approve,
      'director': directorConfirmed,
      'reason': reason,
    };
    return _call('decide', status);
  }
}

void main() {
  late RecordingReviewRemote remote;
  late BusinessReviewRepositoryImpl repository;

  setUp(() {
    remote = RecordingReviewRemote();
    repository = BusinessReviewRepositoryImpl(remoteDataSource: remote);
  });

  Future<BusinessReviewFailureCode?> failureOf(Future<Object?> Function() run) async {
    try {
      await run();
      return null;
    } on BusinessReviewFailure catch (failure) {
      return failure.code;
    }
  }

  test('queue rows map to review items and drop malformed values', () async {
    final items = await repository.queue('reviewer');
    final item = items.single;
    expect(item.businessName, 'Kao Trading');
    expect(item.businessDescription, isNull);
    expect(item.documentPaths, ['a/business-registration/reg-1/doc.pdf']);
    expect(item.isPdf, isTrue);
    expect(item.ownerName, isNull);
    expect(item.legalNameEn, 'KAO TRADING CO., LTD.');
    expect(item.registrationNumberValid, isTrue);
    expect(item.registrationNumberTaken, isFalse);
    expect(item.certificateIssuedOn, DateTime(2026, 9, 1));
    expect(item.certificateFresh, isTrue);
    expect(item.vatPaths, ['a/business-registration/reg-1/vat.png']);
    expect(item.allPaths, hasLength(2));
    expect(item.directorDeclared, isTrue);
    expect(item.dualReview, isTrue);
    expect(item.hasFirstVote, isTrue);
    expect(item.firstDecisionApprove, isFalse);
    expect(item.isOwnVote('reviewer'), isFalse);
    expect(item.submittedAt, isNotNull);
  });

  test('calls are pinned to the reviewer session', () async {
    remote.user = 'someone-else';
    expect(await failureOf(() => repository.queue('reviewer')), BusinessReviewFailureCode.session);
    expect(remote.calls, isEmpty);

    remote
      ..user = 'reviewer'
      ..userAfterCall = 'someone-else';
    expect(await failureOf(() => repository.downloadDocument('reviewer', 'p')), BusinessReviewFailureCode.session);
  });

  test('decision sends the expected reviewer and trimmed reason', () async {
    remote.status = 'awaiting_second';
    final outcome = await repository.decide(
      reviewerId: 'reviewer',
      registrationId: 'reg-1',
      approve: true,
      directorConfirmed: true,
      reason: '  ok  ',
    );
    expect(outcome, BusinessReviewOutcome.awaitingSecond);
    expect(remote.lastDecision, {
      'expected': 'reviewer',
      'id': 'reg-1',
      'approve': true,
      'director': true,
      'reason': 'ok',
    });

    remote.status = 'rejected';
    expect(
      await repository.decide(
        reviewerId: 'reviewer',
        registrationId: 'reg-1',
        approve: false,
        directorConfirmed: true,
        reason: 'Blurry',
      ),
      BusinessReviewOutcome.rejected,
    );
    expect(remote.lastDecision!['director'], isFalse);
  });

  test('approval without the director check never reaches the server', () async {
    expect(
      await failureOf(() => repository.decide(reviewerId: 'reviewer', registrationId: 'reg-1', approve: true)),
      BusinessReviewFailureCode.directorRequired,
    );
    expect(remote.calls, isEmpty);
  });

  test('rejection without a reason never reaches the server', () async {
    expect(
      await failureOf(
        () => repository.decide(reviewerId: 'reviewer', registrationId: 'reg-1', approve: false, reason: ' a '),
      ),
      BusinessReviewFailureCode.reasonRequired,
    );
    expect(remote.calls, isEmpty);
  });

  test('server and storage errors map to review failures', () async {
    final cases = {
      'reviewer_required': BusinessReviewFailureCode.noPermission,
      'mfa_required': BusinessReviewFailureCode.mfaRequired,
      'request_already_reviewed': BusinessReviewFailureCode.alreadyReviewed,
      'request_not_available': BusinessReviewFailureCode.unavailable,
      'owner_kao_id_required': BusinessReviewFailureCode.ownerKaoIdRequired,
      'director_confirmation_required': BusinessReviewFailureCode.directorRequired,
      'certificate_too_old': BusinessReviewFailureCode.certificateTooOld,
      'invalid_registration_number': BusinessReviewFailureCode.invalidNumber,
      'document_files_missing': BusinessReviewFailureCode.documentMissing,
      'inactive_account': BusinessReviewFailureCode.applicantInactive,
      'session_required': BusinessReviewFailureCode.session,
      'something private': BusinessReviewFailureCode.unknown,
    };
    for (final MapEntry(key: message, value: code) in cases.entries) {
      remote.error = PostgrestException(message: message);
      expect(
        await failureOf(
          () => repository.decide(
            reviewerId: 'reviewer',
            registrationId: 'reg-1',
            approve: true,
            directorConfirmed: true,
          ),
        ),
        code,
        reason: message,
      );
    }
    remote.error = const StorageException('Object not found');
    expect(
      await failureOf(() => repository.documentLink('reviewer', 'p')),
      BusinessReviewFailureCode.documentUnavailable,
    );
  });

  test('unexpected server status is not treated as a decision', () async {
    remote.status = 'pending';
    expect(
      await failureOf(
        () =>
            repository.decide(reviewerId: 'reviewer', registrationId: 'reg-1', approve: true, directorConfirmed: true),
      ),
      BusinessReviewFailureCode.unknown,
    );
  });
}
