import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';

import '../../data/repositories/supabase_personal_info_repository.dart';
import '../../domain/entities/personal_info.dart';
import '../../domain/repositories/personal_info_repository.dart';
import '../controllers/reveal_controller.dart';

final personalInfoRepositoryProvider = Provider<PersonalInfoRepository>(
  (ref) => SupabasePersonalInfoRepository(ref.watch(supabaseClientProvider)),
);

final personalInfoProvider = FutureProvider.autoDispose<PersonalInfo>(
  (ref) => ref.watch(personalInfoRepositoryProvider).load(),
);

final revealControllerProvider =
    StateNotifierProvider.autoDispose<RevealController, RevealState>(
  (ref) => RevealController(ref.watch(personalInfoRepositoryProvider)),
);
