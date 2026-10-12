import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/l10n/app_localizations.dart';

/// Only known server codes become UI text. Never expose raw backend errors.
String reviewFailureMessage(AppLocalizations l, Object error, String fallback) {
  final code = error is PostgrestException ? error.message
      : error is StateError && error.message == 'session' ? 'session' : '';
  return switch (code) {
    'mfa_required' || 'owner_mfa_required' => l.mfaSessionRequired,
    'session' => l.contactSessionChanged,
    'reviewer_required' => l.reviewNoPermission,
    'request_already_reviewed' => l.reviewAlreadyDone,
    'request_not_available' => l.reviewUnavailable,
    'document_files_missing' => l.reviewMissingFiles,
    'document_not_ready' || 'invalid_document' => l.reviewInvalidDocument,
    'bank_verified_name_required' => l.reviewBankNameRequired,
    'bank_already_registered' => l.reviewDuplicateDocument,
    'identity_already_registered' => l.reviewDuplicateDocument,
    'invalid_decision' => l.reviewReasonRequired,
    'inactive_account' || 'identity_inactive' => l.issueInactive,
    'approved_identity_required' => l.issueAwaitingReview,
    _ => fallback,
  };
}
