import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/business_document_file.dart';
import '../../domain/entities/business_registration.dart';
import '../../domain/entities/business_registration_step.dart';
import '../../domain/entities/payout_bank_account.dart';
import '../../domain/failures/business_registration_failure.dart';
import '../../domain/usecases/business_registration_use_cases.dart';
import '../services/payout_bank_reader.dart';
import '../states/business_registration_state.dart';

typedef _Flag = BusinessRegistrationState Function(BusinessRegistrationState state, bool on);

final class BusinessRegistrationController
    extends StateNotifier<BusinessRegistrationState> {
  BusinessRegistrationController({
    required this._useCases,
    required this._readPayoutBank,
  }) : super(const BusinessRegistrationState());

  final BusinessRegistrationUseCases _useCases;
  final PayoutBankReader _readPayoutBank;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final current = _withoutWithdrawn(
        await _useCases.getCurrent(_useCases.currentUserId() ?? ''),
      );
      final bank = await _bankOrNull();
      if (!mounted) return;
      state = BusinessRegistrationState(
        registration: current,
        bank: bank,
        step: _resumeStep(current, bank),
        isLoading: false,
      );
    } catch (error) {
      if (mounted) state = state.copyWith(isLoading: false, failure: _code(error));
    }
  }

  Future<bool> saveDetails({
    required String businessType,
    required String businessName,
    required String registrationNumber,
    required String businessCategory,
    String? businessDescription,
  }) async {
    final userId = _useCases.currentUserId();
    if (userId == null) {
      state = state.copyWith(failure: BusinessRegistrationFailureCode.session);
      return false;
    }
    final current = state.registration;
    final description = businessDescription?.trim() ?? '';
    final draft = BusinessRegistration(
      id: current?.id,
      organizationId: current?.organizationId,
      userId: userId,
      businessType: businessType,
      businessName: businessName.trim(),
      registrationNumber: registrationNumber.trim(),
      businessCategory: businessCategory,
      businessDescription: description.isEmpty ? null : description,
      documentId: current?.documentId,
      documentStatus: current?.documentStatus ?? BusinessDocumentStatus.pending,
      createdAt: current?.createdAt,
    );
    return _run((s, on) => s.copyWith(isSaving: on), () async {
      final saved = current?.id == null
          ? await _useCases.createDraft(draft)
          : await _useCases.updateDraft(draft);
      state = state.copyWith(registration: saved, step: BusinessRegistrationStep.document);
    });
  }

  Future<bool> uploadDocument(BusinessDocumentFile file) async {
    final id = state.registration?.id;
    if (id == null) return false;
    return _run((s, on) => s.copyWith(isUploading: on), () async {
      final updated = await _useCases.attachDocument(registrationId: id, file: file);
      state = state.copyWith(registration: updated, documentName: file.name);
    });
  }

  Future<void> refreshBank() async {
    state = state.copyWith(isCheckingBank: true, clearFailure: true);
    final bank = await _bankOrNull();
    if (!mounted) return;
    state = bank == null
        ? state.copyWith(isCheckingBank: false, failure: BusinessRegistrationFailureCode.unknown)
        : state.copyWith(isCheckingBank: false, bank: bank);
  }

  void goTo(BusinessRegistrationStep step) {
    if (state.isBusy || !state.canOpen(step)) return;
    state = state.copyWith(step: step, clearFailure: true);
  }

  void next() {
    final steps = BusinessRegistrationStep.values;
    if (state.step.index == steps.length - 1) return;
    final target = steps[state.step.index + 1];
    if (state.canOpen(target)) return goTo(target);
    state = state.copyWith(failure: switch (state.step) {
      BusinessRegistrationStep.document => BusinessRegistrationFailureCode.documentRequired,
      BusinessRegistrationStep.bankAccount => BusinessRegistrationFailureCode.bankRequired,
      _ => BusinessRegistrationFailureCode.unknown,
    });
  }

  void back() {
    final previous = state.step.previous;
    if (previous != null) goTo(previous);
  }

  Future<bool> submit() async {
    final id = state.registration?.id;
    if (id == null || !state.canOpen(BusinessRegistrationStep.review)) return false;
    return _run((s, on) => s.copyWith(isSubmitting: on), () async {
      final submitted = await _useCases.submit(id);
      state = state.copyWith(registration: submitted);
    });
  }

  Future<bool> cancel() async {
    final id = state.registration?.id;
    if (id == null) return false;
    return _run((s, on) => s.copyWith(isCancelling: on), () async {
      await _useCases.cancelDraft(id);
      state = BusinessRegistrationState(isLoading: false, bank: state.bank);
    });
  }

  Future<bool> refreshStatus() async {
    final id = state.registration?.id;
    if (id == null) return false;
    return _run((s, on) => s.copyWith(isLoading: on), () async {
      final refreshed = await _useCases.refreshStatus(id);
      state = state.copyWith(registration: refreshed);
    });
  }

  void startNew() {
    state = BusinessRegistrationState(isLoading: false, bank: state.bank);
  }

  void dismissFailure() => state = state.copyWith(clearFailure: true);

  Future<bool> _run(_Flag flag, Future<void> Function() action) async {
    if (state.isBusy) return false;
    state = flag(state, true).copyWith(clearFailure: true);
    try {
      await action();
      if (mounted) state = flag(state, false);
      return true;
    } catch (error) {
      if (mounted) state = flag(state, false).copyWith(failure: _code(error));
      return false;
    }
  }

  Future<PayoutBankAccount?> _bankOrNull() async {
    try {
      return await _readPayoutBank();
    } catch (_) {
      return null;
    }
  }

  /// A draft the owner cancelled is stored as rejected without ever being submitted.
  static BusinessRegistration? _withoutWithdrawn(BusinessRegistration? registration) =>
      registration != null && registration.isRejected && registration.submittedAt == null
          ? null
          : registration;

  static BusinessRegistrationStep _resumeStep(
    BusinessRegistration? registration,
    PayoutBankAccount? bank,
  ) {
    if (registration == null || !registration.isDraft) return BusinessRegistrationStep.details;
    if (!registration.hasDocument) return BusinessRegistrationStep.document;
    if (!(bank?.isApproved ?? false)) return BusinessRegistrationStep.bankAccount;
    return BusinessRegistrationStep.review;
  }

  static BusinessRegistrationFailureCode _code(Object error) =>
      error is BusinessRegistrationFailure ? error.code : BusinessRegistrationFailureCode.unknown;
}
