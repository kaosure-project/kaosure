import '../entities/business_registration.dart';

abstract interface class BusinessRegistrationRepository {
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

  Future<BusinessRegistration> attachDocument({
    required String registrationId,
    required String documentId,
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