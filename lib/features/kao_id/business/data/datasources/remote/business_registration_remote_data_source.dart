import 'dart:typed_data';

import '../../models/business_registration_model.dart';

abstract interface class BusinessRegistrationRemoteDataSource {
  String? currentUserId();

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

  Future<void> uploadDocumentFile({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  Future<BusinessRegistrationModel> attachDocument({
    required String registrationId,
    required String documentId,
    required String path,
    required String fileName,
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
