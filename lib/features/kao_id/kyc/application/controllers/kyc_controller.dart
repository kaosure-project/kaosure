import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bank_verification.dart';

import '../../domain/usecases/get_bank_verification_usecase.dart';
import '../../domain/usecases/get_kyc_identity_documents_usecase.dart';
import '../../domain/usecases/get_verification_history_usecase.dart';
import '../../domain/usecases/get_verification_request_usecase.dart';
import '../../domain/usecases/get_verification_usecase.dart';
import '../../domain/usecases/submit_verification_request_usecase.dart';

import '../states/kyc_state.dart';

final class KycController
    extends StateNotifier<KycState> {
  KycController({
    required this._getVerificationUseCase,
    required this._getIdentityDocumentsUseCase,
    required this._getBankVerificationUseCase,
    required this._getVerificationHistoryUseCase,
    required this._getVerificationRequestUseCase,
    required this._submitVerificationRequestUseCase,
  }) : super(KycState.initial());

  final GetVerificationUseCase
      _getVerificationUseCase;

  final GetKycIdentityDocumentsUseCase
      _getIdentityDocumentsUseCase;

  final GetBankVerificationUseCase
      _getBankVerificationUseCase;


  final GetVerificationHistoryUseCase
      _getVerificationHistoryUseCase;

  final GetVerificationRequestUseCase
      _getVerificationRequestUseCase;

  final SubmitVerificationRequestUseCase
      _submitVerificationRequestUseCase;

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final verification =
          await _getVerificationUseCase();

      final verificationRequest =
          await _getVerificationRequestUseCase();

      final identityDocuments =
          await _getIdentityDocumentsUseCase();

      final bankVerification =
          await _getBankVerificationUseCase();

      final verificationHistory =
          await _getVerificationHistoryUseCase();

      state = state.copyWith(
        isLoading: false,
        verification: verification,
        verificationRequest:
            verificationRequest,
        identityDocuments:
            identityDocuments,
        bankVerification:
            bankVerification,
        verificationHistory:
            verificationHistory,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  // ===========================================================================
  // VERIFICATION REQUEST
  // ===========================================================================

  Future<void> submitVerificationRequest({
    required String documentId,
  }) async {
    if (!state.canSubmitVerificationRequest) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _submitVerificationRequestUseCase(
        documentId: documentId,
      );

      await load();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  // ===========================================================================
  // CLEAR
  // ===========================================================================

  void clear() {
    state = KycState.initial();
  }
}