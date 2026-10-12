import '../entities/business_document_file.dart';
import '../entities/business_registration.dart';

abstract interface class BusinessRegistrationRepository {
  String? currentUserId();

  Future<BusinessRegistration> createDraft(
    BusinessRegistration registration,
  );

  Future<BusinessRegistration?> getById(
    String registrationId,
  );

  Future<BusinessRegistration?> getCurrent(
    String userId,
  );

  Future<BusinessRegistration> updateDraft(
    BusinessRegistration registration,
  );

  /// Uploads [file] privately and attaches it to the draft registration.
  Future<BusinessRegistration> attachDocument({
    required String registrationId,
    required BusinessDocumentFile file,
  });

  Future<BusinessRegistration> submit(
    String registrationId,
  );

  Future<BusinessRegistration> refreshStatus(
    String registrationId,
  );

  Future<void> cancelDraft(
    String registrationId,
  );
}