import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bank_verification_model.dart';
import '../models/identity_card_model.dart';
import '../models/passport_model.dart';
import '../models/residence_permit_model.dart';
import '../models/verification_history_model.dart';
import '../models/verification_model.dart';

import 'kyc_remote_datasource.dart';

final class SupabaseKycRemoteDataSource
    implements KycRemoteDataSource {
  const SupabaseKycRemoteDataSource(
    this._client,
  );

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // Verification
  // ---------------------------------------------------------------------------

  @override
  Future<VerificationModel> getVerification() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    final response = await _client
        .from('verifications')
        .select()
        .eq('profile_id', user.id)
        .single();

    return VerificationModel.fromJson(
      response,
    );
  }

  // ---------------------------------------------------------------------------
  // Identity Card
  // ---------------------------------------------------------------------------

  @override
  Future<IdentityCardModel?> getIdentityCard() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    final response = await _client
        .from('identity_documents')
        .select()
        .eq('owner_id', user.id)
        .eq(
          'document_type',
          'identity_card',
        )
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return IdentityCardModel.fromJson(
      response,
    );
  }

  // ---------------------------------------------------------------------------
  // Passport
  // ---------------------------------------------------------------------------

  @override
  Future<PassportModel?> getPassport() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    final response = await _client
        .from('identity_documents')
        .select()
        .eq('owner_id', user.id)
        .eq(
          'document_type',
          'passport',
        )
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return PassportModel.fromJson(
      response,
    );
  }

  // ---------------------------------------------------------------------------
  // Residence Permit
  // ---------------------------------------------------------------------------

  @override
  Future<ResidencePermitModel?>
      getResidencePermit() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    final response = await _client
        .from('identity_documents')
        .select()
        .eq('owner_id', user.id)
        .eq(
          'document_type',
          'residence_permit',
        )
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return ResidencePermitModel.fromJson(
      response,
    );
  }

  // ---------------------------------------------------------------------------
  // Bank Verification
  // ---------------------------------------------------------------------------

  @override
  Future<BankVerificationModel?>
      getBankVerification() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    final response = await _client
        .from('bank_accounts')
        .select()
        .eq('profile_id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return BankVerificationModel.fromJson(
      response,
    );
  }

  // ---------------------------------------------------------------------------
  // Verification History
  // ---------------------------------------------------------------------------

  @override
  Future<List<VerificationHistoryModel>>
      getVerificationHistory() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    final response = await _client
        .from('verification_history')
        .select()
        .eq('profile_id', user.id)
        .order(
          'created_at',
          ascending: false,
        );

    return (response as List)
        .map(
          (json) =>
              VerificationHistoryModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Submit Identity Card
  // ---------------------------------------------------------------------------

  @override
  Future<void> submitIdentityCard(
    IdentityCardModel model,
  ) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    await _client
        .from('identity_documents')
        .upsert(
          model.toJson(),
          onConflict: 'id',
        );

    await _client
        .from('verifications')
        .upsert(
          {
            'profile_id': user.id,
            'identity_card_status':
                model.status,
            'updated_at':
                DateTime.now()
                    .toIso8601String(),
          },
          onConflict: 'profile_id',
        );

    await _client
        .from('verification_history')
        .insert(
          {
            'profile_id': user.id,
            'document_id': model.id,
            'type': 'identity_card',
            'status': model.status,
            'description':
                'ส่งข้อมูลบัตรประชาชน',
            'created_at':
                DateTime.now()
                    .toIso8601String(),
          },
        );
  }

  // ---------------------------------------------------------------------------
  // Submit Passport
  // ---------------------------------------------------------------------------

  @override
  Future<void> submitPassport(
    PassportModel model,
  ) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    await _client
        .from('identity_documents')
        .upsert(
          model.toJson(),
          onConflict: 'id',
        );

    await _client
        .from('verifications')
        .upsert(
          {
            'profile_id': user.id,
            'passport_status':
                model.status,
            'updated_at':
                DateTime.now()
                    .toIso8601String(),
          },
          onConflict: 'profile_id',
        );

    await _client
        .from('verification_history')
        .insert(
          {
            'profile_id': user.id,
            'document_id': model.id,
            'type': 'passport',
            'status': model.status,
            'description':
                'ส่งข้อมูลหนังสือเดินทาง',
            'created_at':
                DateTime.now()
                    .toIso8601String(),
          },
        );
  }

  // ---------------------------------------------------------------------------
  // Submit Residence Permit
  // ---------------------------------------------------------------------------

  @override
  Future<void> submitResidencePermit(
    ResidencePermitModel model,
  ) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    await _client
        .from('identity_documents')
        .upsert(
          model.toJson(),
          onConflict: 'id',
        );

    await _client
        .from('verifications')
        .upsert(
          {
            'profile_id': user.id,
            'residence_permit_status':
                model.status,
            'updated_at':
                DateTime.now()
                    .toIso8601String(),
          },
          onConflict: 'profile_id',
        );

    await _client
        .from('verification_history')
        .insert(
          {
            'profile_id': user.id,
            'document_id': model.id,
            'type': 'residence_permit',
            'status': model.status,
            'description':
                'ส่งข้อมูลใบอนุญาตพำนัก',
            'created_at':
                DateTime.now()
                    .toIso8601String(),
          },
        );
  }

  // ---------------------------------------------------------------------------
  // Submit Bank Verification
  // ---------------------------------------------------------------------------

  @override
  Future<void> submitBankVerification(
    BankVerificationModel model,
  ) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    final now =
        DateTime.now().toIso8601String();

    final bankData = model.toJson();

    bankData['profile_id'] = user.id;
    bankData['updated_at'] = now;

    await _client
        .from('bank_accounts')
        .upsert(
          bankData,
          onConflict: 'id',
        );

    await _client
        .from('verifications')
        .upsert(
          {
            'profile_id': user.id,
            'bank_status': model.status,
            'updated_at': now,
          },
          onConflict: 'profile_id',
        );

    await _client
        .from('verification_history')
        .insert(
          {
            'profile_id': user.id,
            'document_id': model.id,
            'type': 'bank',
            'status': model.status,
            'description':
                'ส่งข้อมูลบัญชีธนาคาร',
            'created_at': now,
          },
        );
  }
}