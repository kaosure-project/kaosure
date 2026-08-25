import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();

  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> register({
    required String email,
    required String password,
  });

  Future<void> forgotPassword({
    required String email,
  });

  /// ส่งอีเมลยืนยันอีกครั้ง
  Future<void> resendEmailVerification();

  /// รีโหลดข้อมูลผู้ใช้ล่าสุด
  Future<UserEntity?> refreshCurrentUser();

  /// ตรวจสอบว่าอีเมลยืนยันแล้วหรือยัง
  Future<bool> isEmailVerified();

  Future<void> logout();
}