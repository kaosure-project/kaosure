import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../../account/presentation/pages/security/mfa_page.dart';
import '../../../../auth/application/providers/auth_provider.dart';
import '../../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../../../dashboard/presentation/widgets/section/section_body.dart';
import '../../../../governance/presentation/widgets/admin/admin_scaffold.dart';
import '../../../application/controllers/business_review_decision_controller.dart';
import '../../../application/providers/business_review_providers.dart';
import '../../../domain/entities/business_review_item.dart';
import '../../../domain/entities/business_review_outcome.dart';
import '../../utils/business_registration_texts.dart';
import '../../utils/business_review_texts.dart';
import '../../widgets/common/failure_banner.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import '../../widgets/review/dual_review_notice.dart';
import '../../widgets/review/review_decision_panel.dart';
import '../../widgets/review/review_document_tile.dart';
import '../../widgets/review/review_info_panel.dart';

class BusinessReviewDetailPage extends ConsumerStatefulWidget {
  const BusinessReviewDetailPage({super.key, required this.item});

  final BusinessReviewItem item;

  @override
  ConsumerState<BusinessReviewDetailPage> createState() => _BusinessReviewDetailPageState();
}

class _BusinessReviewDetailPageState extends ConsumerState<BusinessReviewDetailPage> {
  final _reason = TextEditingController();
  String? _reviewerId;

  @override
  void initState() {
    super.initState();
    _reviewerId = ref.read(authProvider).asData?.value?.id;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _openDocument(BusinessReviewDecisionController controller, String path) async {
    if (widget.item.isPdf) {
      await controller.openExternally(path);
      return;
    }
    final bytes = await controller.loadImage(path);
    if (bytes == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(widget.item.documentName ?? l10n.businessRegStepDocument),
                trailing: IconButton(
                  tooltip: MaterialLocalizations.of(dialogContext).closeButtonTooltip,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _decide(BusinessReviewDecisionController controller, bool approve) async {
    final l10n = AppLocalizations.of(context);
    if (!approve && _reason.text.trim().length < 3) {
      await controller.decide(approve: false, reason: _reason.text);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: approve ? l10n.businessReviewApproveConfirmTitle : l10n.businessReviewRejectConfirmTitle,
      body: approve ? l10n.businessReviewApproveConfirmBody : l10n.businessReviewRejectConfirmBody,
      confirmLabel: approve ? l10n.businessReviewApprove : l10n.businessReviewReject,
      cancelLabel: l10n.cancel,
      destructive: !approve,
    );
    if (!confirmed || !mounted) return;
    final outcome = await controller.decide(approve: approve, reason: _reason.text);
    if (outcome == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(switch (outcome) {
        BusinessReviewOutcome.approved => l10n.businessReviewApprovedMessage,
        BusinessReviewOutcome.rejected => l10n.businessReviewRejectedMessage,
        BusinessReviewOutcome.awaitingSecond => l10n.businessReviewAwaitingSecond,
      }),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reviewerId = _reviewerId;
    if (reviewerId == null || ref.watch(authProvider).asData?.value?.id != reviewerId) {
      return AdminScaffold(child: Center(child: Text(l10n.contactSessionChanged)));
    }

    final item = widget.item;
    final provider = businessReviewDecisionProvider((item: item, reviewerId: reviewerId));
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final submitted = item.submittedAt;
    final missing = l10n.businessReviewNotAvailable;

    return PopScope(
      canPop: !state.busy,
      child: AdminScaffold(
        actions: [
          IconButton(
            tooltip: l10n.twoFactorAuthentication,
            color: AppColors.kaoBlue,
            onPressed: state.busy
                ? null
                : () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const MfaPage())),
            icon: const Icon(Icons.security),
          ),
        ],
        child: SectionBody(
          icon: Icons.storefront_outlined,
          color: AppColors.kaoBlue,
          tint: AppColors.kaoBlueSoft,
          title: item.businessName,
          description: submitted == null
              ? l10n.businessReviewTitle
              : '${l10n.businessReviewTitle} · ${l10n.businessReviewSubmittedOn(
                  MaterialLocalizations.of(context).formatMediumDate(submitted))}',
          top: [
            if (item.dualReview) DualReviewNotice(item: item, ownVote: controller.isOwnVote),
          ],
          start: [
            ReviewInfoPanel(
              title: l10n.businessRegStepDetails,
              icon: Icons.storefront_outlined,
              rows: [
                (l10n.businessRegNameLabel, item.businessName),
                (l10n.businessRegNumberLabel, item.registrationNumber),
                (l10n.businessRegTypeLabel, l10n.businessTypeLabel(item.businessType)),
                (l10n.businessRegCategoryLabel, l10n.businessCategoryLabel(item.businessCategory)),
                if (item.businessDescription != null)
                  (l10n.businessReviewDescription, item.businessDescription!),
              ],
            ),
            ReviewInfoPanel(
              title: l10n.businessReviewApplicant,
              icon: Icons.badge_outlined,
              color: AppColors.kaoGreen,
              rows: [
                (l10n.businessReviewOwnerKaoId, item.ownerKaoId ?? missing),
                (l10n.businessReviewOwnerName, item.ownerName ?? missing),
              ],
            ),
            ReviewInfoPanel(
              title: l10n.businessRegStepBank,
              icon: Icons.account_balance_outlined,
              color: AppColors.kaoTeal,
              rows: [
                if (item.bankAccountLast4 == null)
                  ('', missing)
                else ...[
                  (l10n.businessReviewBankName, item.bankName ?? missing),
                  (l10n.businessReviewBankAccount,
                      l10n.businessReviewBankAccountEnding(item.bankAccountLast4!)),
                  (l10n.businessReviewBankAccountName, item.bankAccountName ?? missing),
                ],
              ],
            ),
          ],
          end: [
            DashboardPanel(
              title: l10n.businessRegStepDocument,
              icon: Icons.description_outlined,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (item.documentPaths.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(l10n.businessReviewErrorDocumentMissing),
                  ),
                for (final path in item.documentPaths)
                  ReviewDocumentTile(
                    name: item.documentName ?? l10n.businessRegStepDocument,
                    isPdf: item.isPdf,
                    viewed: state.viewedPaths.contains(path),
                    onOpen: state.busy ? null : () => _openDocument(controller, path),
                  ),
              ]),
            ),
            DashboardPanel(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (state.failure != null)
                  FailureBanner(
                    message: l10n.businessReviewFailureMessage(state.failure!),
                    onDismiss: controller.dismissFailure,
                  ),
                ReviewDecisionPanel(
                  reasonController: _reason,
                  checked: state.checked,
                  busy: state.busy,
                  ownVote: controller.isOwnVote,
                  documentsViewed: controller.allDocumentsViewed,
                  onCheckedChanged: state.busy || controller.isOwnVote ? null : controller.setChecked,
                  onApprove: controller.canApprove ? () => _decide(controller, true) : null,
                  onReject: controller.canReject ? () => _decide(controller, false) : null,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
