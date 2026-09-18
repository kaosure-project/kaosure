import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/business_registration_model.dart';
import 'business_registration_remote_data_source.dart';

final class BusinessRegistrationRemoteDataSourceImpl
    implements BusinessRegistrationRemoteDataSource {
  BusinessRegistrationRemoteDataSourceImpl({
    required SupabaseClient supabase,
  }) : _supabase = supabase;

  final SupabaseClient _supabase;

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

    if (response == null) {
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
  Future<BusinessRegistrationModel> attachDocument({
    required String registrationId,
    required String documentId,
  }) async {
    final response = await _supabase.rpc(
      'attach_business_registration_document',
      params: {
        'p_registration_id': registrationId,
        'p_document_id': documentId,
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