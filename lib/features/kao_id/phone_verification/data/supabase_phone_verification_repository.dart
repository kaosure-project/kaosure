import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/phone_verification_repository.dart';

class SupabasePhoneVerificationRepository implements PhoneVerificationRepository {
  SupabasePhoneVerificationRepository(this.client);
  final SupabaseClient client;

  @override
  Future<PhoneIdentity> current() async {
    final user = (await client.auth.getUser()).user;
    if (user == null) {
      throw const AuthException('No active user');
    }
    final phone = user.phone ?? '';
    return PhoneIdentity(user.id, phone.isEmpty ? '' : '+${phone.replaceFirst(RegExp(r'^\+'), '')}',
      phone.isNotEmpty && user.phoneConfirmedAt != null);
  }
  @override
  Future<void> send(String phone) async {
    await client.auth.updateUser(UserAttributes(phone: phone));
  }
  @override
  Future<void> resend(String phone) async {
    await client.auth.resend(type: OtpType.phoneChange, phone: phone);
  }
  @override
  Future<void> verify(String phone, String token) async {
    await client.auth.verifyOTP(type: OtpType.phoneChange, phone: phone, token: token);
  }
}
