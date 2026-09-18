import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/business_registration_repository.dart';
import '../datasources/remote/business_registration_remote_data_source.dart';
import '../datasources/remote/business_registration_remote_data_source_impl.dart';
import '../repositories/business_registration_repository_impl.dart';
import '../../../../../core/providers/supabase_provider.dart';

final businessRegistrationRemoteDataSourceProvider =
    Provider<BusinessRegistrationRemoteDataSource>((ref) {
  return BusinessRegistrationRemoteDataSourceImpl(
    supabase: ref.watch(supabaseClientProvider),
  );
});

final businessRegistrationRepositoryProvider =
    Provider<BusinessRegistrationRepository>((ref) {
  return BusinessRegistrationRepositoryImpl(
    remoteDataSource: ref.watch(
      businessRegistrationRemoteDataSourceProvider,
    ),
  );
});