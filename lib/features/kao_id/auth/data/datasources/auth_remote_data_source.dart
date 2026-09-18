import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> getCurrentUser();

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String email,
    required String password,
  });

  Future<void> forgotPassword({
    required String email,
  });

  /// ส่งอีเมลยืนยันใหม่
  Future<void> resendEmailVerification();

  /// รีโหลดข้อมูลผู้ใช้จาก Supabase
  Future<UserModel?> refreshCurrentUser();

  /// ตรวจสอบว่าอีเมลยืนยันแล้วหรือยัง
  Future<bool> isEmailVerified();

  Future<void> logout();
}