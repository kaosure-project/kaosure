import '../../domain/entities/bank_verification.dart';
import '../../domain/entities/identity_card.dart';
import '../../domain/entities/passport.dart';
import '../../domain/entities/residence_permit.dart';
import '../../domain/entities/verification.dart';
import '../../domain/entities/verification_history.dart';
import '../../domain/entities/verification_request.dart';

final class KycState {
  const KycState({
    required this.isLoading,
    required this.verification,
    required this.verificationRequest,
    required this.identityCard,
    required this.passport,
    required this.residencePermit,
    required this.bankVerification,
    required this.verificationHistory,
    required this.errorMessage,
  });

  factory KycState.initial() {
    return const KycState(
      isLoading: false,
      verification: null,
      verificationRequest: null,
      identityCard: null,
      passport: null,
      residencePermit: null,
      bankVerification: null,
      verificationHistory: [],
      errorMessage: null,
    );
  }

  final bool isLoading;

  final Verification? verification;

  final VerificationRequest?
      verificationRequest;

  final IdentityCard? identityCard;

  final Passport? passport;

  final ResidencePermit? residencePermit;

  final BankVerification? bankVerification;

  final List<VerificationHistory>
      verificationHistory;

  final String? errorMessage;

  // ===========================================================================
  // Verification
  // ===========================================================================

  bool get hasVerification =>
      verification != null;

  bool get hasVerificationRequest =>
      verificationRequest != null;

  bool get hasIdentityCard =>
      identityCard != null;

  bool get hasPassport =>
      passport != null;

  bool get hasResidencePermit =>
      residencePermit != null;

  bool get hasBankVerification =>
      bankVerification != null;

  bool get hasVerificationHistory =>
      verificationHistory.isNotEmpty;

  bool get hasError =>
      errorMessage != null;

  // ===========================================================================
  // Verification Request Status
  // ===========================================================================

  bool get isRequestPending =>
      verificationRequest?.isPending ?? false;

  bool get isRequestUnderReview =>
      verificationRequest?.isUnderReview ?? false;

  bool get isRequestApproved =>
      verificationRequest?.isApproved ?? false;

  bool get isRequestRejected =>
      verificationRequest?.isRejected ?? false;

  bool get isRequestCancelled =>
      verificationRequest?.isCancelled ?? false;

  bool get canSubmitVerificationRequest {
    final request = verificationRequest;

    if (request == null) {
      return true;
    }

    return request.canSubmit;
  }

  // ===========================================================================
  // Bank Verification Status
  // ===========================================================================

  bool get isBankPending =>
      bankVerification?.isPending ?? false;

  bool get isBankApproved =>
      bankVerification?.isApproved ?? false;

  bool get isBankRejected =>
      bankVerification?.isRejected ?? false;

  bool get isBankManualReview =>
      bankVerification?.isManualReview ?? false;

  bool get isBankExpired =>
      bankVerification?.isExpired ?? false;

  bool get isBankNameMatched =>
      bankVerification?.isNameMatched ?? false;

  bool get isBankNameMismatched =>
      bankVerification?.isNameMismatched ?? false;

  bool get isBankTrusted =>
      bankVerification?.isTrusted ?? false;

  // ===========================================================================
  // Copy With
  // ===========================================================================

  KycState copyWith({
    bool? isLoading,
    Verification? verification,
    VerificationRequest?
        verificationRequest,
    IdentityCard? identityCard,
    Passport? passport,
    ResidencePermit? residencePermit,
    BankVerification? bankVerification,
    List<VerificationHistory>?
        verificationHistory,
    String? errorMessage,
    bool clearVerification = false,
    bool clearVerificationRequest = false,
    bool clearIdentityCard = false,
    bool clearPassport = false,
    bool clearResidencePermit = false,
    bool clearBankVerification = false,
    bool clearVerificationHistory = false,
    bool clearError = false,
  }) {
    return KycState(
      isLoading:
          isLoading ?? this.isLoading,
      verification:
          clearVerification
              ? null
              : verification ??
                  this.verification,
      verificationRequest:
          clearVerificationRequest
              ? null
              : verificationRequest ??
                  this.verificationRequest,
      identityCard:
          clearIdentityCard
              ? null
              : identityCard ??
                  this.identityCard,
      passport:
          clearPassport
              ? null
              : passport ?? this.passport,
      residencePermit:
          clearResidencePermit
              ? null
              : residencePermit ??
                  this.residencePermit,
      bankVerification:
          clearBankVerification
              ? null
              : bankVerification ??
                  this.bankVerification,
      verificationHistory:
          clearVerificationHistory
              ? const []
              : verificationHistory ??
                  this.verificationHistory,
      errorMessage:
          clearError
              ? null
              : errorMessage ??
                  this.errorMessage,
    );
  }
}