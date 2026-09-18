import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/states/phone_verification_state.dart';

final class PhoneVerificationController
    extends StateNotifier<PhoneVerificationState> {
  PhoneVerificationController(
    this._supabase,
  ) : super(
          const PhoneVerificationState(),
        );

  final SupabaseClient _supabase;

  void load() {
  final user = _supabase.auth.currentUser;

  if (user == null) {
    state = state.copyWith(
      errorMessage: 'User is not signed in.',
    );
    return;
  }

  final phone = user.phone ?? '';

  final isVerified =
      phone.isNotEmpty &&
      user.phoneConfirmedAt != null;

  state = state.copyWith(
    phoneNumber: phone,
    isVerified: isVerified,
    clearError: true,
  );
}

  Future<void> sendOtp({
    required String phoneNumber,
  }) async {
    final phone = phoneNumber.trim();

    if (phone.isEmpty) {
      state = state.copyWith(
        errorMessage: 'กรุณากรอกเบอร์โทรศัพท์',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw const AuthException(
          'User is not signed in.',
        );
      }

      await _supabase.auth.updateUser(
        UserAttributes(
          phone: phone,
        ),
      );

      state = state.copyWith(
        phoneNumber: phone,
        isLoading: false,
        isOtpSent: true,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> verifyOtp({
    required String otp,
  }) async {
    final token = otp.trim();

    if (token.isEmpty) {
      state = state.copyWith(
        errorMessage: 'กรุณากรอกรหัส OTP',
      );
      return;
    }

    if (state.phoneNumber.isEmpty) {
      state = state.copyWith(
        errorMessage: 'ไม่พบหมายเลขโทรศัพท์',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.phoneChange,
        token: token,
        phone: state.phoneNumber,
      );

      load();

      state = state.copyWith(
        isLoading: false,
        isOtpSent: false,
        isVerified: true,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(
      clearError: true,
    );
  }

  void clearOtp() {
    state = state.copyWith(
      otp: '',
      clearError: true,
    );
  }
}