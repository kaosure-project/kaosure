import 'package:flutter/material.dart';

import '../../domain/enums/verification_status.dart';
import 'identity_verification_additional_information_card.dart';
import 'identity_verification_cancelled_card.dart';
import 'identity_verification_completed_card.dart';
import 'identity_verification_not_submitted_card.dart';
import 'identity_verification_pending_card.dart';
import 'identity_verification_rejected_card.dart';

final class IdentityVerificationResultCard
    extends StatelessWidget {
  const IdentityVerificationResultCard({
    super.key,
    required this.status,
    this.reason,
    this.onPrimaryAction,
  });

  final VerificationStatus status;
  final String? reason;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return IdentityVerificationNotSubmittedCard(
          onStart: onPrimaryAction,
        );

      case VerificationStatus.submitted:
      case VerificationStatus.underReview:
        return const IdentityVerificationPendingCard();

      case VerificationStatus.approved:
        return const IdentityVerificationCompletedCard();

      case VerificationStatus.rejected:
        return IdentityVerificationRejectedCard(
          reason: reason,
          onResubmit: onPrimaryAction,
        );

      case VerificationStatus.additionalInformationRequired:
        return IdentityVerificationAdditionalInformationCard(
          reason: reason,
          onUpload: onPrimaryAction,
        );

      case VerificationStatus.cancelled:
        return IdentityVerificationCancelledCard(
          reason: reason,
          onRestart: onPrimaryAction,
        );
    }
  }
}