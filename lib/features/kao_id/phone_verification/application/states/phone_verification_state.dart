import 'package:flutter/foundation.dart';

@immutable
final class PhoneVerificationState {
  const PhoneVerificationState({this.phoneNumber = '', this.pendingPhone = '',
    this.otp = '', this.isLoading = false, this.isOtpSent = false,
    this.isVerified = false, this.statusKnown = false, this.errorMessage,
    this.retryAt});
  final String phoneNumber;
  final String pendingPhone;
  final String otp;
  final bool isLoading;
  final bool isOtpSent;
  final bool isVerified;
  final bool statusKnown;
  /// Stable error code; translated by the presentation layer.
  final String? errorMessage;
  final DateTime? retryAt;

  PhoneVerificationState copyWith({String? phoneNumber, String? pendingPhone,
    String? otp, bool? isLoading, bool? isOtpSent, bool? isVerified,
    bool? statusKnown, String? errorMessage, DateTime? retryAt,
    bool clearError = false}) => PhoneVerificationState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      otp: otp ?? this.otp, isLoading: isLoading ?? this.isLoading,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isVerified: isVerified ?? this.isVerified,
      statusKnown: statusKnown ?? this.statusKnown,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      retryAt: retryAt ?? this.retryAt,
    );
}
