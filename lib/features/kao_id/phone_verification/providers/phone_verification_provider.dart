import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import '../application/states/phone_verification_state.dart';
import '../controllers/phone_verification_controller.dart';
import '../data/supabase_phone_verification_repository.dart';
import '../domain/phone_verification_repository.dart';

final phoneVerificationRepositoryProvider = Provider<PhoneVerificationRepository>(
  (ref) => SupabasePhoneVerificationRepository(ref.watch(supabaseClientProvider)),
);
final phoneVerificationControllerProvider = StateNotifierProvider.autoDispose<
    PhoneVerificationController, PhoneVerificationState>((ref) =>
      PhoneVerificationController(ref.watch(phoneVerificationRepositoryProvider)));
