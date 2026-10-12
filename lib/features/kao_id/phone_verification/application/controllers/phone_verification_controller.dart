import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/phone_verification_state.dart';
import '../../domain/phone_verification_repository.dart';

final class PhoneVerificationController extends StateNotifier<PhoneVerificationState> {
  PhoneVerificationController(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now, super(const PhoneVerificationState());
  final PhoneVerificationRepository _repository;
  final DateTime Function() _clock;
  String? _owner;

  bool get canSend => !state.isLoading &&
      (state.retryAt == null || !_clock().isBefore(state.retryAt!));

  Future<void> load() async {
    if (!mounted || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.current();
      if (!mounted) return;
      if (_owner != null && _owner != user.userId) {
        state = const PhoneVerificationState();
      }
      _owner = user.userId;
      state = state.copyWith(phoneNumber: user.phone, isVerified: user.confirmed,
        statusKnown: true, isLoading: false,
        isOtpSent: user.confirmed && user.phone == state.pendingPhone ? false : state.isOtpSent,
        pendingPhone: user.confirmed && user.phone == state.pendingPhone ? '' : state.pendingPhone);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, statusKnown: false, errorMessage: 'load');
      }
    }
  }

  Future<void> sendOtp({required String phoneNumber}) async {
    if (!mounted || !canSend) return;
    final phone = normalizePhone(phoneNumber);
    if (phone == null) {
      state = state.copyWith(errorMessage: 'phone');
      return;
    }
    final resend = state.isOtpSent && state.pendingPhone == phone;
    // Reserve cooldown before the request, including uncertain network outcomes.
    state = state.copyWith(isLoading: true, clearError: true,
      retryAt: _clock().add(const Duration(seconds: 60)));
    try {
      final user = await _repository.current();
      if (!mounted) return;
      if (_owner != null && _owner != user.userId) {
        state = const PhoneVerificationState(errorMessage: 'session');
        _owner = null;
        return;
      }
      _owner = user.userId;
      if (resend) {
        await _repository.resend(phone);
      } else {
        await _repository.send(phone);
      }
      if (!mounted) return;
      state = state.copyWith(isLoading: false, pendingPhone: phone,
        phoneNumber: user.phone, isVerified: user.confirmed,
        statusKnown: true, isOtpSent: true);
    } catch (_) {
      if (mounted) state = state.copyWith(isLoading: false, errorMessage: 'send');
    }
  }

  Future<void> verifyOtp({required String otp}) async {
    if (!mounted || state.isLoading || !state.isOtpSent) return;
    final token = otp.trim();
    if (!RegExp(r'^[0-9]{6,10}$').hasMatch(token)) {
      state = state.copyWith(errorMessage: 'otp');
      return;
    }
    final target = state.pendingPhone;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final before = await _repository.current();
      if (!mounted) return;
      if (before.userId != _owner) {
        state = const PhoneVerificationState(errorMessage: 'session');
        _owner = null;
        return;
      }
      await _repository.verify(target, token);
      final after = await _repository.current();
      if (!mounted) return;
      if (after.userId != _owner) {
        state = const PhoneVerificationState(errorMessage: 'session');
        _owner = null;
        return;
      }
      final confirmed = after.confirmed && after.phone == target;
      state = state.copyWith(isLoading: false, phoneNumber: after.phone,
        isVerified: after.confirmed, statusKnown: true,
        isOtpSent: !confirmed, pendingPhone: confirmed ? '' : target,
        errorMessage: confirmed ? null : 'pending', clearError: confirmed);
    } catch (_) {
      if (mounted) state = state.copyWith(isLoading: false, errorMessage: 'verify');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearOtp() => state = state.copyWith(otp: '', clearError: true);
}
