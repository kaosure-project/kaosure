import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/business_document_file.dart';
import '../../domain/entities/business_document_kind.dart';
import '../../domain/entities/business_registration.dart';
import '../../domain/entities/business_registration_step.dart';
import '../../domain/failures/business_registration_failure.dart';
import '../../domain/usecases/business_registration_use_cases.dart';
import '../services/kao_id_status_reader.dart';
import '../states/business_registration_state.dart';

typedef _Flag = BusinessRegistrationState Function(BusinessRegistrationState state, bool on);

final class BusinessRegistrationController extends StateNotifier<BusinessRegistrationState> {
  BusinessRegistrationController({required this._useCases, required this._readKaoId})
    : super(const BusinessRegistrationState());

  final BusinessRegistrationUseCases _useCases;
  final KaoIdStatusReader _readKaoId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final current = _withoutWithdrawn(await _useCases.getCurrent(_useCases.currentUserId() ?? ''));
      final kaoId = await _kaoIdOrNull();
      if (!mounted) return;
      state = BusinessRegistrationState(
        registration: current,
        kaoIdActive: kaoId,
        step: _resumeStep(current),
        isLoading: false,
      );
    } catch (error) {
      if (mounted) state = state.copyWith(isLoading: false, failure: _code(error));
    }
  }

  Future<void> refreshKaoId() async {
    state = state.copyWith(isCheckingKaoId: true, clearFailure: true);
    final kaoId = await _kaoIdOrNull();
    if (!mounted) return;
    state = kaoId == null
        ? state.copyWith(isCheckingKaoId: false, failure: BusinessRegistrationFailureCode.unknown)
        : state.copyWith(isCheckingKaoId: false, kaoIdActive: kaoId);
  }

  Future<bool> saveDetails({
    required String businessType,
    required String businessName,
    required String registrationNumber,
    required String businessCategory,
    required DateTime certificateIssuedOn,
    String? legalNameEn,
    String? businessDescription,
  }) async {
    final userId = _useCases.currentUserId();
    if (userId == null) {
      state = state.copyWith(failure: BusinessRegistrationFailureCode.session);
      return false;
    }
    final current = state.registration;
    final description = businessDescription?.trim() ?? '';
    final nameEn = legalNameEn?.trim() ?? '';
    final draft = BusinessRegistration(
      id: current?.id,
      organizationId: current?.organizationId,
      userId: userId,
      businessType: businessType,
      businessName: businessName.trim(),
      registrationNumber: registrationNumber.trim(),
      businessCategory: businessCategory,
      businessDescription: description.isEmpty ? null : description,
      legalNameEn: nameEn.isEmpty ? null : nameEn,
      certificateIssuedOn: DateTime(certificateIssuedOn.year, certificateIssuedOn.month, certificateIssuedOn.day),
      documentId: current?.documentId,
      vatDocumentId: current?.vatDocumentId,
      documentStatus: current?.documentStatus ?? BusinessDocumentStatus.pending,
      createdAt: current?.createdAt,
    );
    return _run((s, on) => s.copyWith(isSaving: on), () async {
      final saved = current?.id == null ? await _useCases.createDraft(draft) : await _useCases.updateDraft(draft);
      state = state.copyWith(registration: saved, step: BusinessRegistrationStep.document);
    });
  }

  Future<bool> uploadDocument(BusinessDocumentFile file, {required BusinessDocumentKind kind}) async {
    final id = state.registration?.id;
    if (id == null) return false;
    return _run((s, on) => s.copyWith(isUploading: on), () async {
      final updated = await _useCases.attachDocument(registrationId: id, kind: kind, file: file);
      state = switch (kind) {
        BusinessDocumentKind.certificate => state.copyWith(registration: updated, documentName: file.name),
        BusinessDocumentKind.vat => state.copyWith(registration: updated, vatDocumentName: file.name),
      };
    });
  }

  Future<bool> removeVatDocument() async {
    final id = state.registration?.id;
    if (id == null) return false;
    return _run((s, on) => s.copyWith(isUploading: on), () async {
      final updated = await _useCases.removeVatDocument(id);
      state = state.copyWith(registration: updated, clearVatDocumentName: true);
    });
  }

  void setDirectorDeclared(bool value) {
    if (state.isBusy) return;
    state = state.copyWith(directorDeclared: value, clearFailure: true);
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
    state = state.copyWith(
      failure: switch (state.step) {
        BusinessRegistrationStep.document => BusinessRegistrationFailureCode.documentRequired,
        BusinessRegistrationStep.authority => BusinessRegistrationFailureCode.declarationRequired,
        _ => BusinessRegistrationFailureCode.unknown,
      },
    );
  }

  void back() {
    final previous = state.step.previous;
    if (previous != null) goTo(previous);
  }

  Future<bool> submit() async {
    final id = state.registration?.id;
    if (id == null || !state.canOpen(BusinessRegistrationStep.review)) return false;
    return _run((s, on) => s.copyWith(isSubmitting: on), () async {
      final submitted = await _useCases.submit(id, directorDeclared: state.directorDeclared);
      state = state.copyWith(registration: submitted);
    });
  }

  Future<bool> cancel() async {
    final id = state.registration?.id;
    if (id == null) return false;
    return _run((s, on) => s.copyWith(isCancelling: on), () async {
      await _useCases.cancelDraft(id);
      state = BusinessRegistrationState(isLoading: false, kaoIdActive: state.kaoIdActive);
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
    state = BusinessRegistrationState(isLoading: false, kaoIdActive: state.kaoIdActive);
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
      if (mounted) {
        final code = _code(error);
        state = flag(
          state,
          false,
        ).copyWith(failure: code, kaoIdActive: code == BusinessRegistrationFailureCode.kaoIdRequired ? false : null);
      }
      return false;
    }
  }

  Future<bool?> _kaoIdOrNull() async {
    try {
      return await _readKaoId();
    } catch (_) {
      return null;
    }
  }

  /// A draft the owner cancelled is stored as rejected without ever being submitted.
  static BusinessRegistration? _withoutWithdrawn(BusinessRegistration? registration) =>
      registration != null && registration.isRejected && registration.submittedAt == null ? null : registration;

  /// The director declaration is never stored on a draft, so a resumed draft stops at that step.
  static BusinessRegistrationStep _resumeStep(BusinessRegistration? registration) {
    if (registration == null || !registration.isDraft) return BusinessRegistrationStep.details;
    if (registration.certificateIssuedOn == null) return BusinessRegistrationStep.details;
    if (!registration.hasDocument) return BusinessRegistrationStep.document;
    return BusinessRegistrationStep.authority;
  }

  static BusinessRegistrationFailureCode _code(Object error) =>
      error is BusinessRegistrationFailure ? error.code : BusinessRegistrationFailureCode.unknown;
}
