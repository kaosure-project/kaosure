import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/organization_bank_draft.dart';
import '../../domain/failures/business_organization_failure.dart';
import '../../domain/usecases/business_organization_use_cases.dart';
import '../states/business_organization_state.dart';

final class BusinessOrganizationController extends StateNotifier<BusinessOrganizationState> {
  BusinessOrganizationController({required this._useCases, required this._newId})
    : super(const BusinessOrganizationState());

  final BusinessOrganizationUseCases _useCases;
  final String Function() _newId;

  /// Kept after a retryable failure so a resend reuses the same request id.
  OrganizationBankDraft? _attempt;

  /// Failures where resending the same request cannot succeed.
  static const _final = {
    BusinessOrganizationFailureCode.nameMismatch,
    BusinessOrganizationFailureCode.invalidBank,
    BusinessOrganizationFailureCode.invalidEvidence,
    BusinessOrganizationFailureCode.duplicate,
    BusinessOrganizationFailureCode.conflict,
    BusinessOrganizationFailureCode.reviewActive,
  };

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final organizations = await _useCases.myOrganizations();
      if (mounted) state = state.copyWith(organizations: organizations, isLoading: false);
    } catch (error) {
      if (mounted) state = state.copyWith(isLoading: false, failure: _code(error));
    }
  }

  Future<bool> submitBank({
    required String organizationId,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String branch,
    required OrganizationBankAccountType type,
    required Uint8List evidenceJpeg,
  }) async {
    if (state.isBusy) return false;
    final previous = _attempt;
    final same =
        previous != null &&
        previous.organizationId == organizationId &&
        previous.bankName == bankName.trim() &&
        previous.accountName == accountName.trim() &&
        previous.accountNumber == accountNumber.trim() &&
        previous.branch == branch.trim() &&
        previous.type == type &&
        listEquals(previous.evidenceJpeg, evidenceJpeg);
    final draft = same
        ? previous
        : OrganizationBankDraft(
            id: _newId(),
            organizationId: organizationId,
            bankName: bankName.trim(),
            accountName: accountName.trim(),
            accountNumber: accountNumber.trim(),
            branch: branch.trim(),
            type: type,
            evidenceJpeg: evidenceJpeg,
          );
    _attempt = draft;
    state = state.copyWith(isSubmitting: true, submitted: false, clearFailure: true);
    try {
      await _useCases.submitBank(draft);
      _attempt = null;
      final organizations = await _useCases.myOrganizations();
      if (mounted) {
        state = state.copyWith(organizations: organizations, isSubmitting: false, submitted: true);
      }
      return true;
    } catch (error) {
      final code = _code(error);
      if (_final.contains(code)) _attempt = null;
      if (mounted) state = state.copyWith(isSubmitting: false, failure: code);
      return false;
    }
  }

  void dismissFailure() => state = state.copyWith(clearFailure: true);

  static BusinessOrganizationFailureCode _code(Object error) =>
      error is BusinessOrganizationFailure ? error.code : BusinessOrganizationFailureCode.unknown;
}
