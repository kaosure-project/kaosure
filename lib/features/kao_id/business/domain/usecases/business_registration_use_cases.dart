import '../entities/business_document_file.dart';
import '../entities/business_document_kind.dart';
import '../entities/business_registration.dart';
import '../repositories/business_registration_repository.dart';

final class BusinessRegistrationUseCases {
  const BusinessRegistrationUseCases(this._repository);

  final BusinessRegistrationRepository _repository;

  String? currentUserId() => _repository.currentUserId();

  Future<BusinessRegistration> createDraft(BusinessRegistration registration) {
    return _repository.createDraft(registration);
  }

  Future<BusinessRegistration?> getById(String registrationId) {
    return _repository.getById(registrationId);
  }

  Future<BusinessRegistration?> getCurrent(String userId) {
    return _repository.getCurrent(userId);
  }

  Future<BusinessRegistration> updateDraft(BusinessRegistration registration) {
    return _repository.updateDraft(registration);
  }

  Future<BusinessRegistration> attachDocument({
    required String registrationId,
    required BusinessDocumentKind kind,
    required BusinessDocumentFile file,
  }) {
    return _repository.attachDocument(registrationId: registrationId, kind: kind, file: file);
  }

  Future<BusinessRegistration> removeVatDocument(String registrationId) {
    return _repository.removeVatDocument(registrationId);
  }

  Future<BusinessRegistration> submit(String registrationId, {required bool directorDeclared}) {
    return _repository.submit(registrationId, directorDeclared: directorDeclared);
  }

  Future<BusinessRegistration> refreshStatus(String registrationId) {
    return _repository.refreshStatus(registrationId);
  }

  Future<void> cancelDraft(String registrationId) {
    return _repository.cancelDraft(registrationId);
  }
}
