import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_provider.dart';
import '../../domain/repositories/business_organization_repository.dart';
import '../datasources/remote/business_organization_remote_data_source.dart';
import '../datasources/remote/business_organization_remote_data_source_impl.dart';
import '../repositories/business_organization_repository_impl.dart';

final businessOrganizationRemoteDataSourceProvider = Provider<BusinessOrganizationRemoteDataSource>((ref) {
  return BusinessOrganizationRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

final businessOrganizationRepositoryProvider = Provider<BusinessOrganizationRepository>((ref) {
  return BusinessOrganizationRepositoryImpl(remoteDataSource: ref.watch(businessOrganizationRemoteDataSourceProvider));
});
