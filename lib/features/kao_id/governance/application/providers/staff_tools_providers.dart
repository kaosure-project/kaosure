import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../data/repositories/supabase_order_issue_repository.dart';
import '../../data/repositories/supabase_review_moderation_repository.dart';
import '../../data/repositories/supabase_system_content_repository.dart';
import '../../data/repositories/supabase_topup_review_repository.dart';
import '../../data/repositories/supabase_withdrawal_review_repository.dart';
import '../../domain/entities/staff_tools.dart';
import '../../domain/repositories/order_issue_repository.dart';
import '../../domain/repositories/review_moderation_repository.dart';
import '../../domain/repositories/system_content_repository.dart';
import '../../domain/repositories/topup_review_repository.dart';
import '../../domain/repositories/withdrawal_review_repository.dart';

final withdrawalReviewRepositoryProvider = Provider<WithdrawalReviewRepository>(
  (ref) => SupabaseWithdrawalReviewRepository(ref.read(supabaseClientProvider)),
);

final systemContentRepositoryProvider = Provider<SystemContentRepository>(
  (ref) => SupabaseSystemContentRepository(ref.read(supabaseClientProvider)),
);

final reviewModerationRepositoryProvider = Provider<ReviewModerationRepository>(
  (ref) => SupabaseReviewModerationRepository(ref.read(supabaseClientProvider)),
);

final orderIssueRepositoryProvider = Provider<OrderIssueRepository>(
  (ref) => SupabaseOrderIssueRepository(ref.read(supabaseClientProvider)),
);

final topupReviewRepositoryProvider = Provider<TopupReviewRepository>(
  (ref) => SupabaseTopupReviewRepository(ref.read(supabaseClientProvider)),
);

/// [StaffTools.none] when signed out.
final staffToolsProvider = FutureProvider.autoDispose<StaffTools>((ref) async {
  final owner = ref.watch(authProvider.select((a) => a.asData?.value?.id));
  if (owner == null) return StaffTools.none;
  return ref.watch(withdrawalReviewRepositoryProvider).tools();
});
