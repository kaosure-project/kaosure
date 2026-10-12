import '../../domain/entities/business_registration.dart';
import '../../domain/entities/business_registration_step.dart';
import '../../domain/entities/payout_bank_account.dart';
import '../../domain/failures/business_registration_failure.dart';

final class BusinessRegistrationState {
  const BusinessRegistrationState({
    this.registration,
    this.step = BusinessRegistrationStep.details,
    this.bank,
    this.documentName,
    this.isLoading = true,
    this.isSaving = false,
    this.isUploading = false,
    this.isSubmitting = false,
    this.isCancelling = false,
    this.isCheckingBank = false,
    this.failure,
  });

  final BusinessRegistration? registration;
  final BusinessRegistrationStep step;
  final PayoutBankAccount? bank;
  final String? documentName;

  final bool isLoading;
  final bool isSaving;
  final bool isUploading;
  final bool isSubmitting;
  final bool isCancelling;
  final bool isCheckingBank;

  final BusinessRegistrationFailureCode? failure;

  bool get isBusy =>
      isLoading || isSaving || isUploading || isSubmitting || isCancelling;

  /// A submitted, approved or rejected registration is shown as a status, not a form.
  bool get showsStatus => registration != null && !registration!.isDraft;

  bool get detailsComplete => registration?.id != null;
  bool get documentComplete => registration?.hasDocument ?? false;
  bool get bankComplete => bank?.isApproved ?? false;

  bool canOpen(BusinessRegistrationStep target) => switch (target) {
        BusinessRegistrationStep.details => true,
        BusinessRegistrationStep.document => detailsComplete,
        BusinessRegistrationStep.bankAccount => detailsComplete && documentComplete,
        BusinessRegistrationStep.review =>
          detailsComplete && documentComplete && bankComplete,
      };

  BusinessRegistrationState copyWith({
    BusinessRegistration? registration,
    bool clearRegistration = false,
    BusinessRegistrationStep? step,
    PayoutBankAccount? bank,
    String? documentName,
    bool clearDocumentName = false,
    bool? isLoading,
    bool? isSaving,
    bool? isUploading,
    bool? isSubmitting,
    bool? isCancelling,
    bool? isCheckingBank,
    BusinessRegistrationFailureCode? failure,
    bool clearFailure = false,
  }) {
    return BusinessRegistrationState(
      registration: clearRegistration ? null : registration ?? this.registration,
      step: step ?? this.step,
      bank: bank ?? this.bank,
      documentName:
          clearDocumentName ? null : documentName ?? this.documentName,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploading: isUploading ?? this.isUploading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCancelling: isCancelling ?? this.isCancelling,
      isCheckingBank: isCheckingBank ?? this.isCheckingBank,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
