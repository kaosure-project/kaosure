import '../entities/business_document_file.dart';
import '../entities/business_document_kind.dart';
import '../entities/business_registration.dart';

abstract interface class BusinessRegistrationRepository {
  String? currentUserId();

  Future<BusinessRegistration> createDraft(BusinessRegistration registration);

  Future<BusinessRegistration?> getById(String registrationId);

  Future<BusinessRegistration?> getCurrent(String userId);

  Future<BusinessRegistration> updateDraft(BusinessRegistration registration);

  /// Uploads [file] privately and attaches it to the draft as [kind]; a new file replaces the old one.
  Future<BusinessRegistration> attachDocument({
    required String registrationId,
    required BusinessDocumentKind kind,
    required BusinessDocumentFile file,
  });

  Future<BusinessRegistration> removeVatDocument(String registrationId);

  /// [directorDeclared]: the applicant confirms they are a director named in the certificate.
  Future<BusinessRegistration> submit(String registrationId, {required bool directorDeclared});

  Future<BusinessRegistration> refreshStatus(String registrationId);

  Future<void> cancelDraft(String registrationId);
}
