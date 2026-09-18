import '../../domain/entities/business_registration.dart';

final class BusinessRegistrationState {
  const BusinessRegistrationState({
    this.registration,
    this.isLoading = false,
    this.isSaving = false,
    this.isUploading = false,
    this.isSubmitting = false,
    this.isCancelling = false,
    this.error,
  });

  final BusinessRegistration? registration;

  final bool isLoading;
  final bool isSaving;
  final bool isUploading;
  final bool isSubmitting;
  final bool isCancelling;

  final String? error;

  bool get hasError => error != null && error!.trim().isNotEmpty;

  bool get isBusy =>
      isLoading ||
      isSaving ||
      isUploading ||
      isSubmitting ||
      isCancelling;

  BusinessRegistrationState copyWith({
    BusinessRegistration? registration,
    bool clearRegistration = false,
    bool? isLoading,
    bool? isSaving,
    bool? isUploading,
    bool? isSubmitting,
    bool? isCancelling,
    String? error,
    bool clearError = false,
  }) {
    return BusinessRegistrationState(
      registration: clearRegistration
          ? null
          : registration ?? this.registration,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploading: isUploading ?? this.isUploading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCancelling: isCancelling ?? this.isCancelling,
      error: clearError ? null : error ?? this.error,
    );
  }
}