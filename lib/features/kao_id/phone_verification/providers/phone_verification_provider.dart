import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase_provider.dart';
import '../application/states/phone_verification_state.dart';
import '../controllers/phone_verification_controller.dart';

final phoneVerificationControllerProvider = StateNotifierProvider<
    PhoneVerificationController,
    PhoneVerificationState
>((ref) {
  final supabase = ref.read(
    supabaseClientProvider,
  );

  return PhoneVerificationController(
    supabase,
  );
});