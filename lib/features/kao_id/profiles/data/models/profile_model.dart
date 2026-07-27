import '../../domain/entities/profile.dart';

final class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.bio,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? bio;
  final String languageCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      languageCode: json['language_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'language_code': languageCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile toEntity() {
    return Profile(
      id: id,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      avatarUrl: avatarUrl,
      bio: bio,
      languageCode: languageCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProfileModel.fromEntity(Profile entity) {
    return ProfileModel(
      id: entity.id,
      displayName: entity.displayName,
      firstName: entity.firstName,
      lastName: entity.lastName,
      avatarUrl: entity.avatarUrl,
      bio: entity.bio,
      languageCode: entity.languageCode,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}