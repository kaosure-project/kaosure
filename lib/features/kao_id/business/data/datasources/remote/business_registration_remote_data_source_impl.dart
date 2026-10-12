import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/business_registration_model.dart';
import 'business_registration_remote_data_source.dart';

final class BusinessRegistrationRemoteDataSourceImpl
    implements BusinessRegistrationRemoteDataSource {
  BusinessRegistrationRemoteDataSourceImpl({
    required this._supabase,
  });

  static const _documentBucket = 'identity-documents';

  final SupabaseClient _supabase;

  @override
  String? currentUserId() => _supabase.auth.currentUser?.id;

  @override
  Future<BusinessRegistrationModel> createDraft(
    BusinessRegistrationModel registration,
  ) async {
    final response = await _supabase.rpc(
      'create_business_registration',
      params: {
        'p_business_type': registration.businessType,
        'p_business_name': registration.businessName,
        'p_registration_number': registration.registrationNumber,
        'p_business_category': registration.businessCategory,
        'p_business_description': registration.businessDescription,
      },
    );

    return _parseRegistration(response);
  }

  @override
  Future<BusinessRegistrationModel?> getById(
    String registrationId,
  ) async {
    final response = await _supabase.rpc(
      'get_business_registration',
      params: {
        'p_registration_id': registrationId,
      },
    );

    if (response == null) {
      return null;
    }

    return _parseRegistration(response);
  }

  @override
  Future<BusinessRegistrationModel?> getCurrent(
    String userId,
  ) async {
    final response = await _supabase.rpc(
      'get_current_business_registration',
    );

    // A composite-returning SQL function yields an all-null row when empty.
    if (response == null || (response is Map && response['id'] == null)) {
      return null;
    }

    return _parseRegistration(response);
  }

  @override
  Future<BusinessRegistrationModel> updateDraft(
    BusinessRegistrationModel registration,
  ) async {
    final registrationId = registration.id;

    if (registrationId == null ||
        registrationId.trim().isEmpty) {
      throw ArgumentError(
        'Registration ID is required to update a draft.',
      );
    }

    final response = await _supabase.rpc(
      'update_business_registration',
      params: {
        'p_registration_id': registrationId,
        'p_business_type': registration.businessType,
        'p_business_name': registration.businessName,
        'p_registration_number': registration.registrationNumber,
        'p_business_category': registration.businessCategory,
        'p_business_description': registration.businessDescription,
      },
    );

    return _parseRegistration(response);
  }

  @override
  Future<void> uploadDocumentFile({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _supabase.storage.from(_documentBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
  }

  @override
  Future<BusinessRegistrationModel> attachDocument({
    required String registrationId,
    required String documentId,
    required String path,
    required String fileName,
  }) async {
    final response = await _supabase.rpc(
      'attach_business_document_r15a',
      params: {
        'p_registration_id': registrationId,
        'p_document_id': documentId,
        'p_path': path,
        'p_file_name': fileName,
      },
    );

    return _parseRegistration(response);
  }

  @override
  Future<BusinessRegistrationModel> submit(
    String registrationId,
  ) async {
    final response = await _supabase.rpc(
      'submit_business_registration',
      params: {
        'p_registration_id': registrationId,
      },
    );

    return _parseRegistration(response);
  }

  @override
  Future<BusinessRegistrationModel> refreshStatus(
    String registrationId,
  ) async {
    final response = await _supabase.rpc(
      'refresh_business_registration_status',
      params: {
        'p_registration_id': registrationId,
      },
    );

    return _parseRegistration(response);
  }

  @override
  Future<void> cancelDraft(
    String registrationId,
  ) async {
    await _supabase.rpc(
      'cancel_business_registration',
      params: {
        'p_registration_id': registrationId,
      },
    );
  }

  BusinessRegistrationModel _parseRegistration(
    dynamic response,
  ) {
    if (response is Map<String, dynamic>) {
      return BusinessRegistrationModel.fromJson(response);
    }

    if (response is Map) {
      return BusinessRegistrationModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    }

    throw StateError(
      'Invalid Business Registration response: '
      '${response.runtimeType}',
    );
  }
}