import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/failures/business_organization_failure.dart';

BusinessOrganizationFailure businessOrganizationFailureFrom(Object error) {
  if (error is BusinessOrganizationFailure) return error;
  if (error is AuthException) {
    return const BusinessOrganizationFailure(BusinessOrganizationFailureCode.session);
  }
  if (error is StorageException) {
    return const BusinessOrganizationFailure(BusinessOrganizationFailureCode.uploadFailed);
  }
  if (error is PostgrestException) {
    return BusinessOrganizationFailure(_codeFor(error.message));
  }
  return const BusinessOrganizationFailure(BusinessOrganizationFailureCode.unknown);
}

BusinessOrganizationFailureCode _codeFor(String message) => switch (message) {
  'authentication_required' => BusinessOrganizationFailureCode.session,
  'account_restricted' => BusinessOrganizationFailureCode.restricted,
  'KAO_ID_REQUIRED' => BusinessOrganizationFailureCode.kaoIdRequired,
  'org_role_required' => BusinessOrganizationFailureCode.roleRequired,
  'business_kao_id_required' => BusinessOrganizationFailureCode.businessKaoIdRequired,
  'bank_name_mismatch' => BusinessOrganizationFailureCode.nameMismatch,
  'bank_review_active' => BusinessOrganizationFailureCode.reviewActive,
  'bank_duplicate' => BusinessOrganizationFailureCode.duplicate,
  'invalid_bank' => BusinessOrganizationFailureCode.invalidBank,
  'invalid_document_paths' || 'invalid_uploaded_file' => BusinessOrganizationFailureCode.invalidEvidence,
  'bank_conflict' => BusinessOrganizationFailureCode.conflict,
  _ => BusinessOrganizationFailureCode.unknown,
};
