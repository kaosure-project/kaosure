import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bank_verification.dart';
import '../../domain/entities/verification.dart';

import '../../domain/usecases/get_bank_verification_usecase.dart';
import '../../domain/usecases/get_identity_card_usecase.dart';
import '../../domain/usecases/get_passport_usecase.dart';
import '../../domain/usecases/get_residence_permit_usecase.dart';
import '../../domain/usecases/get_verification_history_usecase.dart';
import '../../domain/usecases/get_verification_usecase.dart';
import '../../domain/usecases/submit_bank_verification_usecase.dart';

import '../states/kyc_state.dart';

final class KycController
    extends StateNotifier<KycState> {
  KycController({
    required GetVerificationUseCase
        getVerificationUseCase,
    required GetIdentityCardUseCase
        getIdentityCardUseCase,
    required GetPassportUseCase
        getPassportUseCase,
    required GetResidencePermitUseCase
        getResidencePermitUseCase,
    required GetBankVerificationUseCase
        getBankVerificationUseCase,
    required SubmitBankVerificationUseCase
        submitBankVerificationUseCase,
    required GetVerificationHistoryUseCase
        getVerificationHistoryUseCase,
  })  : _getVerificationUseCase =
            getVerificationUseCase,
        _getIdentityCardUseCase =
            getIdentityCardUseCase,
        _getPassportUseCase =
            getPassportUseCase,
        _getResidencePermitUseCase =
            getResidencePermitUseCase,
        _getBankVerificationUseCase =
            getBankVerificationUseCase,
        _submitBankVerificationUseCase =
            submitBankVerificationUseCase,
        _getVerificationHistoryUseCase =
            getVerificationHistoryUseCase,
        super(KycState.initial());

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

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final Verification verification =
          await _getVerificationUseCase();

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
        identityCard: identityCard,
        passport: passport,
        residencePermit: residencePermit,
        bankVerification:
            bankVerification,
        verificationHistory:
            verificationHistory,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

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
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void clear() {
    state = KycState.initial();
  }
}