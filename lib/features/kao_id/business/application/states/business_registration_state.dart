import '../../domain/entities/business_registration.dart';
import '../../domain/entities/business_registration_step.dart';
import '../../domain/failures/business_registration_failure.dart';

final class BusinessRegistrationState {
  const BusinessRegistrationState({
    this.registration,
    this.step = BusinessRegistrationStep.details,
    this.kaoIdActive,
    this.directorDeclared = false,
    this.documentName,
    this.vatDocumentName,
    this.isLoading = true,
    this.isSaving = false,
    this.isUploading = false,
    this.isSubmitting = false,
    this.isCancelling = false,
    this.isCheckingKaoId = false,
    this.failure,
  });

  final BusinessRegistration? registration;
  final BusinessRegistrationStep step;

  /// Whether the applicant holds an active personal Kao ID; null when it could not be read.
  final bool? kaoIdActive;

  /// The applicant ticked the director declaration in this session.
  final bool directorDeclared;
  final String? documentName;
  final String? vatDocumentName;

  final bool isLoading;
  final bool isSaving;
  final bool isUploading;
  final bool isSubmitting;
  final bool isCancelling;
  final bool isCheckingKaoId;

  final BusinessRegistrationFailureCode? failure;

  bool get isBusy => isLoading || isSaving || isUploading || isSubmitting || isCancelling;

  /// A submitted, approved or rejected registration is shown as a status, not a form.
  bool get showsStatus => registration != null && !registration!.isDraft;

  /// Only a verified person (active Kao ID) may register a company.
  bool get needsKaoId => !isLoading && !showsStatus && kaoIdActive != true;

  bool get detailsComplete => registration?.id != null && registration?.certificateIssuedOn != null;
  bool get documentComplete => registration?.hasDocument ?? false;

  bool canOpen(BusinessRegistrationStep target) => switch (target) {
    BusinessRegistrationStep.details => true,
    BusinessRegistrationStep.document => detailsComplete,
    BusinessRegistrationStep.authority => detailsComplete && documentComplete,
    BusinessRegistrationStep.review => detailsComplete && documentComplete && directorDeclared,
  };

  BusinessRegistrationState copyWith({
    BusinessRegistration? registration,
    bool clearRegistration = false,
    BusinessRegistrationStep? step,
    bool? kaoIdActive,
    bool? directorDeclared,
    String? documentName,
    bool clearDocumentName = false,
    String? vatDocumentName,
    bool clearVatDocumentName = false,
    bool? isLoading,
    bool? isSaving,
    bool? isUploading,
    bool? isSubmitting,
    bool? isCancelling,
    bool? isCheckingKaoId,
    BusinessRegistrationFailureCode? failure,
    bool clearFailure = false,
  }) {
    return BusinessRegistrationState(
      registration: clearRegistration ? null : registration ?? this.registration,
      step: step ?? this.step,
      kaoIdActive: kaoIdActive ?? this.kaoIdActive,
      directorDeclared: directorDeclared ?? this.directorDeclared,
      documentName: clearDocumentName ? null : documentName ?? this.documentName,
      vatDocumentName: clearVatDocumentName ? null : vatDocumentName ?? this.vatDocumentName,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploading: isUploading ?? this.isUploading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCancelling: isCancelling ?? this.isCancelling,
      isCheckingKaoId: isCheckingKaoId ?? this.isCheckingKaoId,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
