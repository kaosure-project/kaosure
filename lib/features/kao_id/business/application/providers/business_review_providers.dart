import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../data/providers/business_review_repository_provider.dart';
import '../../domain/entities/business_review_item.dart';
import '../../domain/failures/business_review_failure.dart';
import '../controllers/business_review_decision_controller.dart';
import '../states/business_review_decision_state.dart';

typedef BusinessReviewTarget = ({BusinessReviewItem item, String reviewerId});

final businessReviewQueueProvider =
    FutureProvider.autoDispose<List<BusinessReviewItem>>((ref) {
  final reviewerId = ref.watch(authProvider.select((s) => s.asData?.value?.id));
  if (reviewerId == null) {
    throw const BusinessReviewFailure(BusinessReviewFailureCode.session);
  }
  return ref.watch(businessReviewRepositoryProvider).queue(reviewerId);
});

final externalLinkOpenerProvider = Provider<ExternalLinkOpener>((ref) {
  return (link) => launchUrl(link, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
});

final businessReviewDecisionProvider = StateNotifierProvider.autoDispose
    .family<BusinessReviewDecisionController, BusinessReviewDecisionState, BusinessReviewTarget>(
  (ref, target) => BusinessReviewDecisionController(
    repository: ref.watch(businessReviewRepositoryProvider),
    openLink: ref.watch(externalLinkOpenerProvider),
    item: target.item,
    reviewerId: target.reviewerId,
  ),
);
