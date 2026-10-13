import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/failures/business_review_failure.dart';

BusinessReviewFailure businessReviewFailureFrom(Object error) {
  if (error is BusinessReviewFailure) return error;
  if (error is AuthException) {
    return const BusinessReviewFailure(BusinessReviewFailureCode.session);
  }
  if (error is StorageException) {
    return const BusinessReviewFailure(BusinessReviewFailureCode.documentUnavailable);
  }
  if (error is PostgrestException) {
    return BusinessReviewFailure(_codeFor(error.message));
  }
  return const BusinessReviewFailure(BusinessReviewFailureCode.unknown);
}

BusinessReviewFailureCode _codeFor(String message) => switch (message) {
  'session_required' => BusinessReviewFailureCode.session,
  'reviewer_required' => BusinessReviewFailureCode.noPermission,
  'mfa_required' => BusinessReviewFailureCode.mfaRequired,
  'request_already_reviewed' => BusinessReviewFailureCode.alreadyReviewed,
  'request_not_available' => BusinessReviewFailureCode.unavailable,
  'invalid_decision' => BusinessReviewFailureCode.reasonRequired,
  'document_files_missing' => BusinessReviewFailureCode.documentMissing,
  'owner_kao_id_required' => BusinessReviewFailureCode.ownerKaoIdRequired,
  'director_confirmation_required' => BusinessReviewFailureCode.directorRequired,
  'certificate_too_old' => BusinessReviewFailureCode.certificateTooOld,
  'invalid_registration_number' => BusinessReviewFailureCode.invalidNumber,
  'inactive_account' => BusinessReviewFailureCode.applicantInactive,
  _ => BusinessReviewFailureCode.unknown,
};
