import 'package:equatable/equatable.dart';

/// Aggregate Root ของ Profile
final class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.bio,
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

  @override
  List<Object?> get props => [
        id,
        displayName,
        firstName,
        lastName,
        avatarUrl,
        bio,
        languageCode,
        createdAt,
        updatedAt,
      ];

  Profile copyWith({
    String? id,
    String? displayName,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bio,
    String? languageCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}