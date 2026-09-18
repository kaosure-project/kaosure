import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bank_verification_model.dart';
import '../models/identity_card_model.dart';
import '../models/passport_model.dart';
import '../models/residence_permit_model.dart';
import '../models/verification_history_model.dart';
import '../models/verification_model.dart';
import '../models/verification_request_model.dart';

import 'kyc_remote_datasource.dart';

final class SupabaseKycRemoteDataSource
    implements KycRemoteDataSource {
  const SupabaseKycRemoteDataSource(
    this._client,
  );

  final SupabaseClient _client;

  User _requireUser() {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    return user;
  }

  // ===========================================================================
  // Verification
  // ===========================================================================

  @override
  Future<VerificationModel>
      getVerification() async {
    final user = _requireUser();

    final response = await _client
        .from('verifications')
        .select()
        .eq('profile_id', user.id)
        .maybeSingle();

    if (response == null) {
      throw Exception(
        'Verification record not found.',
      );
    }

    return VerificationModel.fromJson(
      response,
    );
  }

  // ===========================================================================
  // Verification Request
  // ===========================================================================

  @override
  Future<VerificationRequestModel?>
      getVerificationRequest() async {
    final user = _requireUser();

    final response = await _client
        .from('verification_requests')
        .select()
        .eq('requested_by', user.id)
        .order(
          'created_at',
          ascending: false,
        )
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return VerificationRequestModel.fromJson(
      response,
    );
  }

  @override
  Future<void>
      submitVerificationRequest() async {
    final user = _requireUser();

    await _client
        .from('verification_requests')
        .insert({
      'requested_by': user.id,
      'status': 'pending',
    });
  }

  // ===========================================================================
  // Identity Card
  // ===========================================================================

  @override
  Future<IdentityCardModel?>
      getIdentityCard() async {
    final user = _requireUser();

    final response = await _client
        .from('identity_cards')
        .select()
        .eq('owner_id', user.id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return IdentityCardModel.fromJson(
      response,
    );
  }

  // ===========================================================================
  // Passport
  // ===========================================================================

  @override
  Future<PassportModel?> getPassport() async {
    final user = _requireUser();

    final response = await _client
        .from('passports')
        .select()
        .eq('owner_id', user.id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return PassportModel.fromJson(
      response,
    );
  }

  // ===========================================================================
  // Residence Permit
  // ===========================================================================

  @override
  Future<ResidencePermitModel?>
      getResidencePermit() async {
    final user = _requireUser();

    final response = await _client
        .from('residence_permits')
        .select()
        .eq('owner_id', user.id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return ResidencePermitModel.fromJson(
      response,
    );
  }

  // ===========================================================================
  // Bank Verification
  // ===========================================================================

  @override
  Future<BankVerificationModel?>
      getBankVerification() async {
    final user = _requireUser();

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

  // ===========================================================================
  // Verification History
  // ===========================================================================

  @override
  Future<List<VerificationHistoryModel>>
      getVerificationHistory() async {
    final user = _requireUser();

    final response = await _client
        .from('verification_logs')
        .select()
        .eq('profile_id', user.id)
        .order(
          'created_at',
          ascending: false,
        );

    return response
        .map(
          (row) =>
              VerificationHistoryModel.fromJson(
            row,
          ),
        )
        .toList();
  }

  // ===========================================================================
  // Submit Identity Card
  // ===========================================================================

  @override
  Future<void> submitIdentityCard(
    IdentityCardModel model,
  ) async {
    throw UnimplementedError(
      'Identity card submission is not connected yet.',
    );
  }

  // ===========================================================================
  // Submit Passport
  // ===========================================================================

  @override
  Future<void> submitPassport(
    PassportModel model,
  ) async {
    throw UnimplementedError(
      'Passport submission is not connected yet.',
    );
  }

  // ===========================================================================
  // Submit Residence Permit
  // ===========================================================================

  @override
  Future<void> submitResidencePermit(
    ResidencePermitModel model,
  ) async {
    throw UnimplementedError(
      'Residence permit submission is not connected yet.',
    );
  }

  // ===========================================================================
  // Submit Bank Verification
  // ===========================================================================

  @override
  Future<void> submitBankVerification(
    BankVerificationModel model,
  ) async {
    throw UnimplementedError(
      'Bank verification submission is not connected yet.',
    );
  }
}