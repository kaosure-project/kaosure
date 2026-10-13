import 'dart:typed_data';

import '../../../domain/entities/business_document_kind.dart';
import '../../models/business_registration_model.dart';

abstract interface class BusinessRegistrationRemoteDataSource {
  String? currentUserId();

  Future<BusinessRegistrationModel> createDraft(BusinessRegistrationModel registration);

  Future<BusinessRegistrationModel?> getById(String registrationId);

  Future<BusinessRegistrationModel?> getCurrent(String userId);

  Future<BusinessRegistrationModel> updateDraft(BusinessRegistrationModel registration);

  Future<void> uploadDocumentFile({required String path, required Uint8List bytes, required String contentType});

  Future<BusinessRegistrationModel> attachDocument({
    required String registrationId,
    required BusinessDocumentKind kind,
    required String documentId,
    required String path,
    required String fileName,
  });

  Future<BusinessRegistrationModel> removeVatDocument(String registrationId);

  Future<BusinessRegistrationModel> submit(String registrationId, {required bool directorDeclared});

  Future<BusinessRegistrationModel> refreshStatus(String registrationId);

  Future<void> cancelDraft(String registrationId);
}
