import 'package:flutter/foundation.dart';

import '../../domain/entities/business_organization.dart';
import '../../domain/entities/organization_bank_draft.dart';
import '../../domain/failures/business_organization_failure.dart';
import '../../domain/repositories/business_organization_repository.dart';
import '../datasources/remote/business_organization_remote_data_source.dart';
import '../mappers/business_organization_failure_mapper.dart';
import '../models/business_organization_model.dart';

final class BusinessOrganizationRepositoryImpl implements BusinessOrganizationRepository {
  BusinessOrganizationRepositoryImpl({required this._remoteDataSource});

  static const maxEvidenceBytes = 10 * 1024 * 1024;

  final BusinessOrganizationRemoteDataSource _remoteDataSource;

  @override
  String? currentUserId() => _remoteDataSource.currentUserId();

  @override
  Future<List<BusinessOrganization>> myOrganizations() => _guard(() async {
    final rows = await _remoteDataSource.myOrganizations();
    return [for (final row in rows) BusinessOrganizationModel.fromJson(row)];
  });

  @override
  Future<void> submitBank(OrganizationBankDraft draft) => _guard(() async {
    final owner = _remoteDataSource.currentUserId();
    if (owner == null) {
      throw const BusinessOrganizationFailure(BusinessOrganizationFailureCode.session);
    }
    final bytes = draft.evidenceJpeg;
    if (bytes.isEmpty || bytes.length > maxEvidenceBytes) {
      throw const BusinessOrganizationFailure(BusinessOrganizationFailureCode.invalidEvidence);
    }
    // Must match the path rule enforced by submit_org_bank_r27c.
    final path = '$owner/business-bank/${draft.id}/evidence.jpg';
    try {
      await _remoteDataSource.uploadEvidence(path: path, bytes: bytes);
    } catch (error) {
      // A retry after a lost response finds its own earlier upload already in place.
      final saved = await _remoteDataSource.downloadEvidence(path);
      if (saved == null || !listEquals(saved, bytes)) rethrow;
    }
    if (_remoteDataSource.currentUserId() != owner) {
      throw const BusinessOrganizationFailure(BusinessOrganizationFailureCode.session);
    }
    await _remoteDataSource.submitBank(
      organizationId: draft.organizationId,
      id: draft.id,
      bankName: draft.bankName.trim(),
      accountName: draft.accountName.trim(),
      accountNumber: draft.accountNumber.trim(),
      branch: draft.branch.trim(),
      type: draft.type.name,
      evidencePath: path,
    );
  });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (error) {
      throw businessOrganizationFailureFrom(error);
    }
  }
}
