import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/failures/business_registration_failure.dart';

BusinessRegistrationFailure businessRegistrationFailureFrom(Object error) {
  if (error is BusinessRegistrationFailure) return error;
  if (error is AuthException) {
    return const BusinessRegistrationFailure(BusinessRegistrationFailureCode.session);
  }
  if (error is StorageException) {
    return const BusinessRegistrationFailure(BusinessRegistrationFailureCode.invalidFile);
  }
  if (error is PostgrestException) {
    return BusinessRegistrationFailure(_codeFor(error.message));
  }
  return const BusinessRegistrationFailure(BusinessRegistrationFailureCode.unknown);
}

BusinessRegistrationFailureCode _codeFor(String message) => switch (message) {
  'AUTH_REQUIRED' || 'authentication_required' || 'Authentication required' => BusinessRegistrationFailureCode.session,
  'account_restricted' || 'Active profile not found' => BusinessRegistrationFailureCode.restricted,
  'KAO_ID_REQUIRED' => BusinessRegistrationFailureCode.kaoIdRequired,
  'ACTIVE_BUSINESS_REGISTRATION_EXISTS' => BusinessRegistrationFailureCode.activeExists,
  'invalid_business_name' ||
  'invalid_business_type' ||
  'invalid_business_category' ||
  'invalid_business_description' => BusinessRegistrationFailureCode.invalidName,
  'invalid_registration_number' => BusinessRegistrationFailureCode.invalidNumber,
  'invalid_legal_name_en' => BusinessRegistrationFailureCode.invalidNameEn,
  'invalid_certificate_date' => BusinessRegistrationFailureCode.invalidCertificateDate,
  'certificate_too_old' => BusinessRegistrationFailureCode.certificateTooOld,
  'CERTIFICATE_DATE_REQUIRED' => BusinessRegistrationFailureCode.certificateDateRequired,
  'DIRECTOR_DECLARATION_REQUIRED' => BusinessRegistrationFailureCode.declarationRequired,
  'DRAFT_NOT_FOUND_OR_NOT_EDITABLE' ||
  'DRAFT_NOT_FOUND_OR_NOT_CANCELLABLE' ||
  'REGISTRATION_NOT_DRAFT' ||
  'REGISTRATION_NOT_FOUND' => BusinessRegistrationFailureCode.notEditable,
  'BUSINESS_DOCUMENT_REQUIRED' => BusinessRegistrationFailureCode.documentRequired,
  'invalid_uploaded_file' ||
  'invalid_document_paths' ||
  'invalid_document' ||
  'document_conflict' => BusinessRegistrationFailureCode.invalidFile,
  'Organization registration number already exists' => BusinessRegistrationFailureCode.duplicateRegistration,
  _ => BusinessRegistrationFailureCode.unknown,
};
