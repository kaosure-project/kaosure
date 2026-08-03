class SessionEntity {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final bool isAuthenticated;

  const SessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.isAuthenticated,
  });

  factory SessionEntity.unauthenticated() {
    return const SessionEntity(
      accessToken: '',
      refreshToken: '',
      expiresAt: null,
      isAuthenticated: false,
    );
  }
}