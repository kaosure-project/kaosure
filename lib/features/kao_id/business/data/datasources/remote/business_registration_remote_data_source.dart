import '../../models/business_registration_model.dart';

abstract interface class BusinessRegistrationRemoteDataSource {
  Future<BusinessRegistrationModel> createDraft(
    BusinessRegistrationModel registration,
  );

  Future<BusinessRegistrationModel?> getById(
    String registrationId,
  );

  Future<BusinessRegistrationModel?> getCurrent(
    String userId,
  );

  Future<BusinessRegistrationModel> updateDraft(
    BusinessRegistrationModel registration,
  );

  Future<BusinessRegistrationModel> attachDocument({
    required String registrationId,
    required String documentId,
  });

  Future<BusinessRegistrationModel> submit(
    String registrationId,
  );

  Future<BusinessRegistrationModel> refreshStatus(
    String registrationId,
  );

  Future<void> cancelDraft(
    String registrationId,
  );
}