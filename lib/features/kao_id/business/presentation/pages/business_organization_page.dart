import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../app/routes/kao_id_routes.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/business_organization_providers.dart';
import '../../domain/entities/business_organization.dart';
import '../../domain/entities/organization_bank_draft.dart';
import '../utils/business_organization_texts.dart';
import '../widgets/common/failure_banner.dart';
import '../widgets/layout/registration_layout.dart';
import '../widgets/organization/organization_bank_form.dart';
import '../widgets/organization/organization_card.dart';

/// Companies the signed-in person belongs to, with the business Kao ID and company bank account.
class BusinessOrganizationPage extends ConsumerStatefulWidget {
  const BusinessOrganizationPage({super.key});

  static const String routeName = KaoIdRoutes.businessOrganizations;

  @override
  ConsumerState<BusinessOrganizationPage> createState() => _BusinessOrganizationPageState();
}

class _BusinessOrganizationPageState extends ConsumerState<BusinessOrganizationPage> {
  String? _owner;

  /// Organization whose bank form is open.
  String? _adding;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
  }

  Future<bool> _submit(
    BusinessOrganization org, {
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String branch,
    required OrganizationBankAccountType type,
    required Uint8List evidenceJpeg,
  }) async {
    final ok = await ref
        .read(businessOrganizationControllerProvider.notifier)
        .submitBank(
          organizationId: org.organizationId,
          bankName: bankName,
          accountName: accountName,
          accountNumber: accountNumber,
          branch: branch,
          type: type,
          evidenceJpeg: evidenceJpeg,
        );
    if (!ok || !mounted) return ok;
    setState(() => _adding = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).businessOrgBankSubmitted)));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value?.id;
    if (_owner == null || user != _owner) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.contactSessionChanged)),
      );
    }
    final state = ref.watch(businessOrganizationControllerProvider);
    final controller = ref.read(businessOrganizationControllerProvider.notifier);
    final failure = state.failure;
    return PopScope(
      canPop: !state.isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: l10n.authCheckAgain,
              onPressed: state.isBusy ? null : controller.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RegistrationLayout(
          title: l10n.businessOrgTitle,
          subtitle: l10n.businessOrgSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (failure != null)
                FailureBanner(message: l10n.businessOrgFailureMessage(failure), onDismiss: controller.dismissFailure),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.organizations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(l10n.businessOrgEmpty, textAlign: TextAlign.center),
                )
              else
                for (final (index, org) in state.organizations.indexed) ...[
                  if (index > 0) const Divider(height: 48),
                  OrganizationCard(
                    organization: org,
                    busy: state.isBusy,
                    onAddBank: org.canSubmitBank && _adding != org.organizationId
                        ? () => setState(() => _adding = org.organizationId)
                        : null,
                  ),
                  if (_adding == org.organizationId && org.canSubmitBank) ...[
                    const SizedBox(height: 24),
                    OrganizationBankForm(
                      key: ValueKey('org-bank-form-${org.organizationId}'),
                      legalName: org.legalName ?? org.name,
                      legalNameEn: org.legalNameEn,
                      busy: state.isSubmitting,
                      onPickEvidence: ref.read(organizationEvidencePickerProvider),
                      onSubmit:
                          ({
                            required bankName,
                            required accountName,
                            required accountNumber,
                            required branch,
                            required type,
                            required evidenceJpeg,
                          }) => _submit(
                            org,
                            bankName: bankName,
                            accountName: accountName,
                            accountNumber: accountNumber,
                            branch: branch,
                            type: type,
                            evidenceJpeg: evidenceJpeg,
                          ),
                      onCancel: () => setState(() => _adding = null),
                    ),
                  ],
                ],
            ],
          ),
        ),
      ),
    );
  }
}
