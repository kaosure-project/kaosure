import '../../../devices/domain/entities/device.dart';
import '../../../kyc/domain/entities/verification.dart';
import '../../../account/domain/entities/profile.dart';
import '../../../sessions/domain/entities/session.dart';

final class DashboardState {
  const DashboardState({
    required this.isLoading,
    required this.profile,
    required this.currentDevice,
    required this.currentSession,
    required this.verification,
    required this.errorMessage,
  });

  factory DashboardState.initial() {
    return const DashboardState(
      isLoading: false,
      profile: null,
      currentDevice: null,
      currentSession: null,
      verification: null,
      errorMessage: null,
    );
  }

  final bool isLoading;

  final Profile? profile;

  final Device? currentDevice;

  final Session? currentSession;

  final Verification? verification;

  final String? errorMessage;

  bool get hasProfile => profile != null;

  bool get hasDevice => currentDevice != null;

  bool get hasSession => currentSession != null;

  bool get isVerified => verification != null;

  bool get hasError => errorMessage != null;

  DashboardState copyWith({
    bool? isLoading,
    Profile? profile,
    Device? currentDevice,
    Session? currentSession,
    Verification? verification,
    String? errorMessage,
    bool clearProfile = false,
    bool clearDevice = false,
    bool clearSession = false,
    bool clearVerification = false,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      profile: clearProfile
          ? null
          : profile ?? this.profile,
      currentDevice: clearDevice
          ? null
          : currentDevice ?? this.currentDevice,
      currentSession: clearSession
          ? null
          : currentSession ?? this.currentSession,
      verification: clearVerification
          ? null
          : verification ?? this.verification,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}