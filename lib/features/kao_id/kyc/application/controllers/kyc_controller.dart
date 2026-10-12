import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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

  int _generation = 0;

  Future<void> load() async {
    if (!mounted) return;
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: true, clearError: true,
      loadedResources: const {}, failedResources: const {},
    );
    bool current() => mounted && generation == _generation;

    Future<void> fetch<T>(KycResource resource, Future<T> Function() read,
        KycState Function(KycState, T) apply) async {
      try {
        final value = await read();
        if (!current()) return;
        state = apply(state, value).copyWith(
          loadedResources: Set.unmodifiable({...state.loadedResources, resource}),
        );
      } catch (error) {
        if (!current()) return;
        // Never log document numbers, bank data, tokens or raw server messages.
        debugPrint('KYC load failed: ${resource.name} (${error.runtimeType})');
        state = state.copyWith(
          failedResources: Set.unmodifiable({...state.failedResources, resource}),
          errorMessage: 'KYC data unavailable',
        );
      }
    }

    await Future.wait([
      fetch(KycResource.verification, () => _getVerificationUseCase(),
          (s, value) => s.copyWith(verification: value)),
      fetch(KycResource.request, () => _getVerificationRequestUseCase(),
          (s, value) => s.copyWith(verificationRequest: value,
              clearVerificationRequest: value == null)),
      fetch(KycResource.documents, () => _getIdentityDocumentsUseCase(),
          (s, value) => s.copyWith(identityDocuments: value)),
      fetch(KycResource.bank, () => _getBankVerificationUseCase(),
          (s, value) => s.copyWith(bankVerification: value,
              clearBankVerification: value == null)),
      fetch(KycResource.history, () => _getVerificationHistoryUseCase(),
          (s, value) => s.copyWith(verificationHistory: value)),
    ]);
    if (current()) state = state.copyWith(isLoading: false);
  }

  // ===========================================================================
  // VERIFICATION REQUEST
  // ===========================================================================

  Future<void> submitVerificationRequest({
    required String documentId,
  }) async {
    if (!mounted || !state.canSubmitVerificationRequest) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    final generation = ++_generation;
    try {
      await _submitVerificationRequestUseCase(
        documentId: documentId,
      );

      if (!mounted || generation != _generation) return;
      await load();
    } catch (error) {
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'KYC request failed',
      );
    }
  }

  // ===========================================================================
  // CLEAR
  // ===========================================================================

  void clear() {
    _generation++;
    if (!mounted) return;
    state = KycState.initial();
  }
}