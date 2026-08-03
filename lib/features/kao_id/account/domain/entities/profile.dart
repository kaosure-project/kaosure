import 'package:equatable/equatable.dart';

/// Aggregate Root ของ Profile
final class Profile extends Equatable {
  const Profile({
    required this.id,

    this.username,
    this.displayName,
    this.firstName,
    this.lastName,

    required this.avatarUrl,
    required this.bio,

    this.languageCode,

    // Kao ID
    required this.accountLevel,
    required this.accountStatus,
    required this.role,
    required this.position,

    required this.createdAt,
    required this.updatedAt,
  });

  /// UUID จาก auth.users
  final String id;

  /// Public username (Unique)
  ///
  /// กำหนดหลัง Complete Profile
  final String? username;

  /// Public display name
  ///
  /// สามารถซ้ำกับคนอื่นได้
  final String? displayName;

  /// Legal first name
  final String? firstName;

  /// Legal last name
  final String? lastName;

  /// Profile avatar
  final String? avatarUrl;

  /// User biography
  final String? bio;

  /// Preferred language
  final String? languageCode;

  /// Kao ID account level
  ///
  /// registered
  /// verified
  /// business
  /// organization
  final String accountLevel;

  /// Account status
  ///
  /// active
  /// pending
  /// restricted
  /// suspended
  /// closed
  final String accountStatus;

  /// User role
  ///
  /// user
  /// admin
  /// developer
  /// support
  /// kyc_officer
  final String role;

  /// Employee position
  ///
  /// NULL for normal users
  final String? position;

  final DateTime createdAt;

  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        firstName,
        lastName,
        avatarUrl,
        bio,
        languageCode,
        accountLevel,
        accountStatus,
        role,
        position,
        createdAt,
        updatedAt,
      ];

  Profile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bio,
    String? languageCode,
    String? accountLevel,
    String? accountStatus,
    String? role,
    String? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      languageCode: languageCode ?? this.languageCode,
      accountLevel: accountLevel ?? this.accountLevel,
      accountStatus: accountStatus ?? this.accountStatus,
      role: role ?? this.role,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}