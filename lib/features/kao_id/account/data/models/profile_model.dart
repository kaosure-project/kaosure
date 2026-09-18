import '../../domain/entities/profile.dart';

final class ProfileModel {
  const ProfileModel({
    required this.id,
    this.username,
    this.displayName,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.bio,
    this.languageCode,
    required this.accountLevel,
    required this.accountStatus,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Username ของบริการ
  ///
  /// ไม่ใช่ข้อกำหนดของ Kao ID
  final String? username;

  /// ชื่อที่แสดงต่อสาธารณะ
  final String? displayName;

  /// ชื่อตามกฎหมาย
  final String? firstName;

  /// นามสกุลตามกฎหมาย
  final String? lastName;

  final String? avatarUrl;

  final String? bio;

  /// ภาษาที่ต้องการใช้
  final String? languageCode;

  /// registered | verified | business | organization
  final String accountLevel;

  /// active | pending | restricted | suspended | closed
  final String accountStatus;

  /// user | admin | developer | support | kyc_officer
  final String role;

  final DateTime createdAt;

  final DateTime updatedAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,

      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,

      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      languageCode: json['language_code'] as String?,

      accountLevel: json['account_level'] as String,
      accountStatus: json['account_status'] as String,
      role: json['role'] as String,

      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'language_code': languageCode,
      'account_level': accountLevel,
      'account_status': accountStatus,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile toEntity() {
    return Profile(
      id: id,

      username: username,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,

      avatarUrl: avatarUrl,
      bio: bio,
      languageCode: languageCode,

      accountLevel: accountLevel,
      accountStatus: accountStatus,
      role: role,

      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProfileModel.fromEntity(Profile entity) {
    return ProfileModel(
      id: entity.id,

      username: entity.username,
      displayName: entity.displayName,
      firstName: entity.firstName,
      lastName: entity.lastName,

      avatarUrl: entity.avatarUrl,
      bio: entity.bio,
      languageCode: entity.languageCode,

      accountLevel: entity.accountLevel,
      accountStatus: entity.accountStatus,
      role: entity.role,

      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}