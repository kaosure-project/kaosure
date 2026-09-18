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
    required this.accountLevel,
    required this.accountStatus,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  /// UUID จาก auth.users
  final String id;

  /// Username ของบริการ
  ///
  /// ไม่ใช่ข้อกำหนดของ Kao ID
  /// อาจถูกใช้โดย Service เช่น Marketplace
  final String? username;

  /// ชื่อที่แสดงต่อสาธารณะ
  final String? displayName;

  /// ชื่อตามกฎหมาย
  ///
  /// ข้อมูลนี้จะเกี่ยวข้องกับกระบวนการ KYC
  final String? firstName;

  /// นามสกุลตามกฎหมาย
  ///
  /// ข้อมูลนี้จะเกี่ยวข้องกับกระบวนการ KYC
  final String? lastName;

  /// รูปโปรไฟล์
  final String? avatarUrl;

  /// ประวัติหรือคำอธิบายของผู้ใช้
  final String? bio;

  /// ภาษาที่ต้องการใช้
  final String? languageCode;

  /// ระดับบัญชี Kao ID
  ///
  /// registered
  /// verified
  /// business
  /// organization
  final String accountLevel;

  /// สถานะบัญชี
  ///
  /// active
  /// pending
  /// restricted
  /// suspended
  /// closed
  final String accountStatus;

  /// บทบาทของบัญชี
  ///
  /// user
  /// admin
  /// developer
  /// support
  /// kyc_officer
  final String role;

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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}