import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/remote/profile_remote_datasource.dart';
import '../../data/datasources/remote/profile_remote_datasource_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/create_profile.dart';
import '../../domain/usecases/delete_profile.dart';
import '../../domain/usecases/exists_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
  ),
);

final profileRepositoryProvider =
    Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ref.watch(profileRemoteDataSourceProvider),
  ),
);

final getProfileUseCaseProvider =
    Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(
    ref.watch(profileRepositoryProvider),
  ),
);

final createProfileUseCaseProvider =
    Provider<CreateProfileUseCase>(
  (ref) => CreateProfileUseCase(
    ref.watch(profileRepositoryProvider),
  ),
);

final updateProfileUseCaseProvider =
    Provider<UpdateProfileUseCase>(
  (ref) => UpdateProfileUseCase(
    ref.watch(profileRepositoryProvider),
  ),
);

final deleteProfileUseCaseProvider =
    Provider<DeleteProfileUseCase>(
  (ref) => DeleteProfileUseCase(
    ref.watch(profileRepositoryProvider),
  ),
);

final existsProfileUseCaseProvider =
    Provider<ExistsProfileUseCase>(
  (ref) => ExistsProfileUseCase(
    ref.watch(profileRepositoryProvider),
  ),
);