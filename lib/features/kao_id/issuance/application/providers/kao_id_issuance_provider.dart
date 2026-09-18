import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers.dart';
import '../../data/datasources/supabase_kao_id_issuance_datasource.dart';
import '../../data/repositories/kao_id_issuance_repository_impl.dart';
import '../../domain/entities/kao_id_identity.dart';
import '../../domain/repositories/kao_id_issuance_repository.dart';

final kaoIdIssuanceDataSourceProvider =
    Provider<SupabaseKaoIdIssuanceDataSource>(
  (ref) => SupabaseKaoIdIssuanceDataSource(
    ref.watch(supabaseClientProvider),
  ),
);

final kaoIdIssuanceRepositoryProvider =
    Provider<KaoIdIssuanceRepository>(
  (ref) => KaoIdIssuanceRepositoryImpl(
    ref.watch(kaoIdIssuanceDataSourceProvider),
  ),
);

final currentKaoIdIdentityProvider =
    FutureProvider<KaoIdIdentity?>(
  (ref) => ref.watch(kaoIdIssuanceRepositoryProvider).getCurrentIdentity(),
);

final issueCurrentUserKaoIdProvider =
    Provider<Future<String> Function()>(
  (ref) {
    return () async {
      final repository = ref.read(kaoIdIssuanceRepositoryProvider);
      final kaoId = await repository.issueCurrentUserKaoId();
      ref.invalidate(currentKaoIdIdentityProvider);
      return kaoId;
    };
  },
);
