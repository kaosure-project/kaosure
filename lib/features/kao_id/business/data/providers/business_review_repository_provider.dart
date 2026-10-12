import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_provider.dart';
import '../../domain/repositories/business_review_repository.dart';
import '../datasources/remote/business_review_remote_data_source.dart';
import '../datasources/remote/business_review_remote_data_source_impl.dart';
import '../repositories/business_review_repository_impl.dart';

final businessReviewRemoteDataSourceProvider = Provider<BusinessReviewRemoteDataSource>((ref) {
  return BusinessReviewRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

final businessReviewRepositoryProvider = Provider<BusinessReviewRepository>((ref) {
  return BusinessReviewRepositoryImpl(
    remoteDataSource: ref.watch(businessReviewRemoteDataSourceProvider),
  );
});
