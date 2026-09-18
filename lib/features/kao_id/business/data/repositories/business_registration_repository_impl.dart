import '../../domain/entities/business_registration.dart';
import '../../domain/repositories/business_registration_repository.dart';
import '../datasources/remote/business_registration_remote_data_source.dart';
import '../models/business_registration_model.dart';

final class BusinessRegistrationRepositoryImpl
    implements BusinessRegistrationRepository {
  const BusinessRegistrationRepositoryImpl({
    required BusinessRegistrationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final BusinessRegistrationRemoteDataSource _remoteDataSource;

  @override
  Future<BusinessRegistration> createDraft(
    BusinessRegistration registration,
  ) async {
    final model = BusinessRegistrationModel.fromEntity(registration);

    final result = await _remoteDataSource.createDraft(model);

    return result;
  }

  @override
  Future<BusinessRegistration?> getById(
    String registrationId,
  ) async {
    final result = await _remoteDataSource.getById(registrationId);

    return result;
  }

  @override
  Future<BusinessRegistration?> getCurrent(
    String userId,
  ) async {
    final result = await _remoteDataSource.getCurrent(userId);

    return result;
  }

  @override
  Future<BusinessRegistration> updateDraft(
    BusinessRegistration registration,
  ) async {
    final model = BusinessRegistrationModel.fromEntity(registration);

    final result = await _remoteDataSource.updateDraft(model);

    return result;
  }

  @override
  Future<BusinessRegistration> attachDocument({
    required String registrationId,
    required String documentId,
  }) async {
    final result = await _remoteDataSource.attachDocument(
      registrationId: registrationId,
      documentId: documentId,
    );

    return result;
  }

  @override
  Future<BusinessRegistration> submit(
    String registrationId,
  ) async {
    final result = await _remoteDataSource.submit(registrationId);

    return result;
  }

  @override
  Future<BusinessRegistration> refreshStatus(
    String registrationId,
  ) async {
    final result = await _remoteDataSource.refreshStatus(registrationId);

    return result;
  }

  @override
  Future<void> cancelDraft(
    String registrationId,
  ) async {
    await _remoteDataSource.cancelDraft(registrationId);
  }
}