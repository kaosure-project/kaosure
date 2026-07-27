import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_remote_datasource_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    ref.read(supabaseClientProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authRemoteDataSourceProvider),
  );
});

final forgotPasswordUseCaseProvider = Provider((ref) {
  return ForgotPasswordUseCase(
    ref.read(authRepositoryProvider),
  );
});

final getCurrentUserUseCaseProvider = Provider((ref) {
  return GetCurrentUserUseCase(
    ref.read(authRepositoryProvider),
  );
});

final loginUseCaseProvider = Provider((ref) {
  return LoginUseCase(
    ref.read(authRepositoryProvider),
  );
});

final logoutUseCaseProvider = Provider((ref) {
  return LogoutUseCase(
    ref.read(authRepositoryProvider),
  );
});

final registerUseCaseProvider = Provider((ref) {
  return RegisterUseCase(
    ref.read(authRepositoryProvider),
  );
});