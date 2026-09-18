import '../entities/business_registration.dart';
import '../repositories/business_registration_repository.dart';

final class BusinessRegistrationUseCases {
  const BusinessRegistrationUseCases(
    this._repository,
  );

  final BusinessRegistrationRepository _repository;

  Future<BusinessRegistration> createDraft(
    BusinessRegistration registration,
  ) {
    return _repository.createDraft(registration);
  }

  Future<BusinessRegistration?> getById(
    String registrationId,
  ) {
    return _repository.getById(registrationId);
  }

  Future<BusinessRegistration?> getCurrent(
    String userId,
  ) {
    return _repository.getCurrent(userId);
  }

  Future<BusinessRegistration> updateDraft(
    BusinessRegistration registration,
  ) {
    return _repository.updateDraft(registration);
  }

  Future<BusinessRegistration> attachDocument({
    required String registrationId,
    required String documentId,
  }) {
    return _repository.attachDocument(
      registrationId: registrationId,
      documentId: documentId,
    );
  }

  Future<BusinessRegistration> submit(
    String registrationId,
  ) {
    return _repository.submit(registrationId);
  }

  Future<BusinessRegistration> refreshStatus(
    String registrationId,
  ) {
    return _repository.refreshStatus(registrationId);
  }

  Future<void> cancelDraft(
    String registrationId,
  ) {
    return _repository.cancelDraft(registrationId);
  }
}