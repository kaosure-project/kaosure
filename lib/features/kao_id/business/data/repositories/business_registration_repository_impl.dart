import 'package:uuid/uuid.dart';

import '../../domain/entities/business_document_file.dart';
import '../../domain/entities/business_registration.dart';
import '../../domain/failures/business_registration_failure.dart';
import '../../domain/repositories/business_registration_repository.dart';
import '../datasources/remote/business_registration_remote_data_source.dart';
import '../mappers/business_registration_failure_mapper.dart';
import '../models/business_registration_model.dart';

final class BusinessRegistrationRepositoryImpl
    implements BusinessRegistrationRepository {
  BusinessRegistrationRepositoryImpl({
    required this._remoteDataSource,
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final BusinessRegistrationRemoteDataSource _remoteDataSource;
  final String Function() _newId;

  @override
  String? currentUserId() => _remoteDataSource.currentUserId();

  @override
  Future<BusinessRegistration> createDraft(
    BusinessRegistration registration,
  ) =>
      _guard(() => _remoteDataSource.createDraft(
            BusinessRegistrationModel.fromEntity(registration),
          ));

  @override
  Future<BusinessRegistration?> getById(String registrationId) =>
      _guard(() => _remoteDataSource.getById(registrationId));

  @override
  Future<BusinessRegistration?> getCurrent(String userId) =>
      _guard(() => _remoteDataSource.getCurrent(userId));

  @override
  Future<BusinessRegistration> updateDraft(
    BusinessRegistration registration,
  ) =>
      _guard(() => _remoteDataSource.updateDraft(
            BusinessRegistrationModel.fromEntity(registration),
          ));

  @override
  Future<BusinessRegistration> attachDocument({
    required String registrationId,
    required BusinessDocumentFile file,
  }) =>
      _guard(() async {
        final owner = _remoteDataSource.currentUserId();
        if (owner == null) {
          throw const BusinessRegistrationFailure(BusinessRegistrationFailureCode.session);
        }
        if (!file.isAcceptable) {
          throw const BusinessRegistrationFailure(BusinessRegistrationFailureCode.invalidFile);
        }
        final documentId = _newId();
        // Must match the path rule enforced by attach_business_document_r15a.
        final path = '$owner/business-registration/$registrationId/'
            '$documentId.${file.storageExtension}';
        await _remoteDataSource.uploadDocumentFile(
          path: path,
          bytes: file.bytes,
          contentType: file.mimeType,
        );
        return _remoteDataSource.attachDocument(
          registrationId: registrationId,
          documentId: documentId,
          path: path,
          fileName: file.name,
        );
      });

  @override
  Future<BusinessRegistration> submit(String registrationId) =>
      _guard(() => _remoteDataSource.submit(registrationId));

  @override
  Future<BusinessRegistration> refreshStatus(String registrationId) =>
      _guard(() => _remoteDataSource.refreshStatus(registrationId));

  @override
  Future<void> cancelDraft(String registrationId) =>
      _guard(() => _remoteDataSource.cancelDraft(registrationId));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (error) {
      throw businessRegistrationFailureFrom(error);
    }
  }
}
