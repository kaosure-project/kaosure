import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bank_verification.dart';

import '../../domain/usecases/get_bank_verification_usecase.dart';
import '../../domain/usecases/get_identity_card_usecase.dart';
import '../../domain/usecases/get_passport_usecase.dart';
import '../../domain/usecases/get_residence_permit_usecase.dart';
import '../../domain/usecases/get_verification_history_usecase.dart';
import '../../domain/usecases/get_verification_request_usecase.dart';
import '../../domain/usecases/get_verification_usecase.dart';
import '../../domain/usecases/submit_bank_verification_usecase.dart';
import '../../domain/usecases/submit_verification_request_usecase.dart';

import '../states/kyc_state.dart';

final class KycController
    extends StateNotifier<KycState> {
  KycController({
    required this._getVerificationUseCase,
    required this._getIdentityCardUseCase,
    required this._getPassportUseCase,
    required this._getResidencePermitUseCase,
    required this._getBankVerificationUseCase,
    required this._submitBankVerificationUseCase,
    required this._getVerificationHistoryUseCase,
    required this._getVerificationRequestUseCase,
    required this._submitVerificationRequestUseCase,
  }) : super(KycState.initial());

  final GetVerificationUseCase
      _getVerificationUseCase;

  final GetIdentityCardUseCase
      _getIdentityCardUseCase;

  final GetPassportUseCase
      _getPassportUseCase;

  final GetResidencePermitUseCase
      _getResidencePermitUseCase;

  final GetBankVerificationUseCase
      _getBankVerificationUseCase;

  final SubmitBankVerificationUseCase
      _submitBankVerificationUseCase;

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

      final identityCard =
          await _getIdentityCardUseCase();

      final passport =
          await _getPassportUseCase();

      final residencePermit =
          await _getResidencePermitUseCase();

      final bankVerification =
          await _getBankVerificationUseCase();

      final verificationHistory =
          await _getVerificationHistoryUseCase();

      state = state.copyWith(
        isLoading: false,
        verification: verification,
        verificationRequest:
            verificationRequest,
        identityCard: identityCard,
        passport: passport,
        residencePermit:
            residencePermit,
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
  // BANK VERIFICATION
  // ===========================================================================

  Future<void> submitBankVerification(
    BankVerification bankVerification,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _submitBankVerificationUseCase(
        bankVerification,
      );

      final updatedBankVerification =
          await _getBankVerificationUseCase();

      final verificationHistory =
          await _getVerificationHistoryUseCase();

      state = state.copyWith(
        isLoading: false,
        bankVerification:
            updatedBankVerification,
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

  Future<void>
      submitVerificationRequest() async {
    if (!state.canSubmitVerificationRequest) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _submitVerificationRequestUseCase();

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