import '../../domain/entities/profile.dart';

final class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  final Profile? profile;
  final bool isLoading;
  final String? errorMessage;

  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  factory ProfileState.initial() {
    return const ProfileState();
  }
}