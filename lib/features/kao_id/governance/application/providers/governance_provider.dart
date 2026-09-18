import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers.dart';
import '../../data/datasources/governance_remote_datasource.dart';
import '../../data/datasources/supabase_governance_remote_datasource.dart';
import '../../data/repositories/governance_repository_impl.dart';
import '../../domain/entities/governance_access.dart';
import '../../domain/repositories/governance_repository.dart';
import '../controllers/governance_controller.dart';
import '../states/governance_state.dart';

final governanceRemoteDataSourceProvider =
    Provider<GovernanceRemoteDataSource>(
  (ref) => SupabaseGovernanceRemoteDataSource(
    ref.watch(supabaseClientProvider),
  ),
);

final governanceRepositoryProvider =
    Provider<GovernanceRepository>(
  (ref) => GovernanceRepositoryImpl(
    ref.watch(
      governanceRemoteDataSourceProvider,
    ),
  ),
);

final governanceAccessProvider =
    FutureProvider<GovernanceAccess>(
  (ref) {
    return ref
        .watch(governanceRepositoryProvider)
        .getAccess();
  },
);

final governanceControllerProvider =
    StateNotifierProvider<
        GovernanceController,
        GovernanceState>(
  (ref) {
    return GovernanceController(
      ref.watch(governanceRepositoryProvider),
    );
  },
);
