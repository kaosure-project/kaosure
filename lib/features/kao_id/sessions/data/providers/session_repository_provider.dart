import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_provider.dart';

import '../datasources/session_remote_datasource.dart';
import '../datasources/session_remote_datasource_impl.dart';
import '../repositories/session_repository_impl.dart';

import '../../domain/repositories/session_repository.dart';

final sessionRemoteDataSourceProvider =
    Provider<SessionRemoteDataSource>((ref) {
  return SessionRemoteDataSourceImpl(
    supabase: ref.watch(supabaseClientProvider),
  );
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(
    remoteDataSource: ref.watch(sessionRemoteDataSourceProvider),
  );
});