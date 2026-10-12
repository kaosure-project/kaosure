import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../domain/entities/business_registration.dart';
import '../../../../domain/entities/business_registration_step.dart';
import '../../../../domain/entities/payout_bank_account.dart';
import '../../../utils/business_registration_texts.dart';
import '../../common/step_actions.dart';
import '../../common/step_header.dart';
import 'review_section.dart';

class ReviewStep extends StatefulWidget {
  const ReviewStep({
    super.key,
    required this.registration,
    required this.bank,
    required this.documentName,
    required this.submitting,
    required this.onEdit,
    required this.onBack,
    required this.onSubmit,
  });

  final BusinessRegistration registration;
  final PayoutBankAccount bank;
  final String? documentName;
  final bool submitting;
  final ValueChanged<BusinessRegistrationStep> onEdit;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  State<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<ReviewStep> {
  bool _consent = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.registration;
    final description = r.businessDescription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeader(title: l10n.businessRegReviewHeading,
            description: l10n.businessRegReviewDescription),
        ReviewSection(
          title: l10n.businessRegStepDetails,
          onEdit: () => widget.onEdit(BusinessRegistrationStep.details),
          rows: [
            (l10n.businessRegTypeLabel, l10n.businessTypeLabel(r.businessType)),
            (l10n.businessRegNameLabel, r.businessName),
            (l10n.businessRegNumberLabel, r.registrationNumber),
            (l10n.businessRegCategoryLabel, l10n.businessCategoryLabel(r.businessCategory)),
            if (description != null && description.isNotEmpty)
              (l10n.businessRegDescriptionLabel, description),
          ],
        ),
        const Divider(height: 1),
        ReviewSection(
          title: l10n.businessRegStepDocument,
          onEdit: () => widget.onEdit(BusinessRegistrationStep.document),
          rows: [(l10n.businessRegDocumentUploaded, widget.documentName ?? '✓')],
        ),
        const Divider(height: 1),
        ReviewSection(
          title: l10n.businessRegStepBank,
          rows: [(widget.bank.bankName ?? '', widget.bank.maskedNumber ?? '')],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _consent,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: widget.submitting ? null : (value) => setState(() => _consent = value ?? false),
          title: Text(l10n.businessRegConsent, style: Theme.of(context).textTheme.bodyMedium),
        ),
        StepActions(
          primaryLabel: l10n.businessRegSubmit,
          onPrimary: _consent ? widget.onSubmit : null,
          onBack: widget.onBack,
          busy: widget.submitting,
        ),
      ],
    );
  }
}
