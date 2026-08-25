import 'package:flutter/foundation.dart';

@immutable
final class PhoneVerificationState {
  const PhoneVerificationState({
    this.phoneNumber = '',
    this.otp = '',
    this.isLoading = false,
    this.isOtpSent = false,
    this.isVerified = false,
    this.errorMessage,
  });

  final String phoneNumber;
  final String otp;

  final bool isLoading;
  final bool isOtpSent;
  final bool isVerified;

  final String? errorMessage;

  PhoneVerificationState copyWith({
    String? phoneNumber,
    String? otp,
    bool? isLoading,
    bool? isOtpSent,
    bool? isVerified,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PhoneVerificationState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otp: otp ?? this.otp,
      isLoading: isLoading ?? this.isLoading,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isVerified: isVerified ?? this.isVerified,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}