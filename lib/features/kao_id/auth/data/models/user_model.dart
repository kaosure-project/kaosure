import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.avatarUrl,
    required super.emailConfirmed,
  });

  factory UserModel.fromSupabase(Map<String, dynamic> profile) {
    return UserModel(
      id: profile['id'] as String,
      email: profile['email'] as String? ?? '',
      displayName: profile['display_name'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      emailConfirmed: profile['email_confirmed'] as bool? ?? false,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      emailConfirmed: entity.emailConfirmed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'email_confirmed': emailConfirmed,
    };
  }
}