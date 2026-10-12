import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../app/routes/kao_id_routes.dart';
import '../../../kyc/presentation/bank/bank_verification_page.dart';
import '../../application/controllers/business_registration_controller.dart';
import '../../application/providers/business_registration_provider.dart';
import '../../application/states/business_registration_state.dart';
import '../../domain/entities/business_registration_step.dart';
import '../../domain/entities/payout_bank_account.dart';
import '../utils/business_registration_texts.dart';
import '../widgets/common/failure_banner.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/layout/registration_layout.dart';
import '../widgets/status/registration_status_view.dart';
import '../widgets/stepper/registration_stepper.dart';
import '../widgets/steps/bank/bank_account_step.dart';
import '../widgets/steps/details/business_details_step.dart';
import '../widgets/steps/document/business_document_step.dart';
import '../widgets/steps/review/review_step.dart';

class BusinessRegistrationPage extends ConsumerWidget {
  const BusinessRegistrationPage({super.key});

  static const String routeName = KaoIdRoutes.businessRegistration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(businessRegistrationControllerProvider);
    final controller = ref.read(businessRegistrationControllerProvider.notifier);
    final failure = state.failure;
    return Scaffold(
      appBar: AppBar(),
      body: RegistrationLayout(
        title: l10n.businessRegTitle,
        subtitle: l10n.businessRegSubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!state.showsStatus && !state.isLoading)
              RegistrationStepper(
                current: state.step,
                canOpen: state.canOpen,
                onSelect: controller.goTo,
              ),
            if (failure != null) ...[
              FailureBanner(
                message: l10n.businessFailureMessage(failure),
                onDismiss: controller.dismissFailure,
              ),
              const SizedBox(height: 20),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey((state.showsStatus, state.isLoading && !state.showsStatus, state.step)),
                child: _body(context, ref, state, controller),
              ),
            ),
            if (!state.showsStatus && state.registration?.id != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: state.isBusy ? null : () => _cancel(context, controller),
                child: Text(l10n.businessRegCancelDraft),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    BusinessRegistrationState state,
    BusinessRegistrationController controller,
  ) {
    final registration = state.registration;
    if (state.showsStatus) {
      return RegistrationStatusView(
        registration: registration!,
        refreshing: state.isLoading,
        onRefresh: controller.refreshStatus,
        onStartNew: controller.startNew,
        onDone: () => _leave(context),
      );
    }
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return switch (state.step) {
      BusinessRegistrationStep.details => BusinessDetailsStep(
          initial: registration,
          busy: state.isSaving,
          onSave: controller.saveDetails,
        ),
      BusinessRegistrationStep.document => BusinessDocumentStep(
          uploaded: state.documentComplete,
          uploading: state.isUploading,
          fileName: state.documentName,
          onPick: () async {
            final file = await ref.read(businessDocumentPickerProvider)();
            if (file != null) await controller.uploadDocument(file);
          },
          onBack: controller.back,
          onContinue: controller.next,
        ),
      BusinessRegistrationStep.bankAccount => BankAccountStep(
          bank: state.bank,
          checking: state.isCheckingBank,
          onVerify: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BankVerificationPage()),
            );
            await controller.refreshBank();
          },
          onCheckAgain: controller.refreshBank,
          onBack: controller.back,
          onContinue: controller.next,
        ),
      BusinessRegistrationStep.review => ReviewStep(
          registration: registration!,
          bank: state.bank ?? PayoutBankAccount.none,
          documentName: state.documentName,
          submitting: state.isSubmitting,
          onEdit: controller.goTo,
          onBack: controller.back,
          onSubmit: () => _submit(context, controller),
        ),
    };
  }

  Future<void> _submit(BuildContext context, BusinessRegistrationController controller) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.businessRegSubmitConfirmTitle,
      body: l10n.businessRegSubmitConfirmBody,
      confirmLabel: l10n.businessRegSubmit,
      cancelLabel: l10n.businessRegKeepEditing,
    );
    if (confirmed) await controller.submit();
  }

  Future<void> _cancel(BuildContext context, BusinessRegistrationController controller) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.businessRegCancelConfirmTitle,
      body: l10n.businessRegCancelConfirmBody,
      confirmLabel: l10n.businessRegCancelDraft,
      cancelLabel: l10n.businessRegKeepEditing,
      destructive: true,
    );
    if (confirmed) await controller.cancel();
  }

  void _leave(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(KaoIdRoutes.dashboard);
    }
  }
}
