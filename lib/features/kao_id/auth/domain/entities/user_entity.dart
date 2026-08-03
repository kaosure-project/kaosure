class UserEntity {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final bool emailConfirmed;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.emailConfirmed,
  });
}