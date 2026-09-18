import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/business_registration.dart';
import '../states/business_registration_state.dart';

typedef LoadCurrentBusinessRegistration =
    Future<BusinessRegistration?> Function(String userId);

typedef SaveBusinessRegistration = Future<BusinessRegistration> Function(
  BusinessRegistration registration,
);

typedef UpdateBusinessRegistration = Future<BusinessRegistration> Function(
  BusinessRegistration registration,
);

typedef AttachBusinessDocument = Future<String?> Function(
  String registrationId,
);

typedef SubmitBusinessRegistration = Future<BusinessRegistration> Function(
  String registrationId,
);

typedef CancelBusinessRegistration = Future<void> Function(
  String registrationId,
);

final class BusinessRegistrationController
    extends StateNotifier<BusinessRegistrationState> {
  BusinessRegistrationController({
    required this.loadCurrentRegistration,
    required this.saveDraft,
    required UpdateBusinessRegistration updateDraft,
    required this.attachDocument,
    required this.submitRegistration,
    required this.cancelRegistration,
  })  : _updateDraft = updateDraft,
        super(const BusinessRegistrationState());

  final LoadCurrentBusinessRegistration loadCurrentRegistration;
  final SaveBusinessRegistration saveDraft;
  final UpdateBusinessRegistration _updateDraft;
  final AttachBusinessDocument attachDocument;
  final SubmitBusinessRegistration submitRegistration;
  final CancelBusinessRegistration cancelRegistration;

  void setRegistration(
    BusinessRegistration registration,
  ) {
    state = state.copyWith(
      registration: registration,
      clearError: true,
    );
  }

  void clearError() {
    state = state.copyWith(
      clearError: true,
    );
  }

  Future<BusinessRegistration?> loadCurrent(
    String userId,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await loadCurrentRegistration(userId);

      state = state.copyWith(
        registration: result,
        isLoading: false,
      );

      return result;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );

      rethrow;
    }
  }

  Future<BusinessRegistration> createDraft(
    BusinessRegistration registration,
  ) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
    );

    try {
      final result = await saveDraft(registration);

      state = state.copyWith(
        registration: result,
        isSaving: false,
      );

      return result;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        error: error.toString(),
      );

      rethrow;
    }
  }

  Future<BusinessRegistration> updateDraft(
    BusinessRegistration registration,
  ) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
    );

    try {
      final result = await _updateDraft(registration);

      state = state.copyWith(
        registration: result,
        isSaving: false,
      );

      return result;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        error: error.toString(),
      );

      rethrow;
    }
  }

  Future<String?> uploadDocument(
    String registrationId,
  ) async {
    state = state.copyWith(
      isUploading: true,
      clearError: true,
    );

    try {
      final documentId = await attachDocument(
        registrationId,
      );

      if (documentId != null &&
          documentId.trim().isNotEmpty) {
        final current = state.registration;

        if (current != null) {
          state = state.copyWith(
            registration: current.copyWith(
              documentId: documentId,
            ),
          );
        }
      }

      state = state.copyWith(
        isUploading: false,
      );

      return documentId;
    } catch (error) {
      state = state.copyWith(
        isUploading: false,
        error: error.toString(),
      );

      rethrow;
    }
  }

  Future<BusinessRegistration> submit(
    String registrationId,
  ) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      final result = await submitRegistration(
        registrationId,
      );

      state = state.copyWith(
        registration: result,
        isSubmitting: false,
      );

      return result;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        error: error.toString(),
      );

      rethrow;
    }
  }

  Future<void> cancel(
    String registrationId,
  ) async {
    state = state.copyWith(
      isCancelling: true,
      clearError: true,
    );

    try {
      await cancelRegistration(
        registrationId,
      );

      state = state.copyWith(
        clearRegistration: true,
        isCancelling: false,
      );
    } catch (error) {
      state = state.copyWith(
        isCancelling: false,
        error: error.toString(),
      );

      rethrow;
    }
  }
}