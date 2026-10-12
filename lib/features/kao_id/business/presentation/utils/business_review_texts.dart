import 'package:kaosure/l10n/app_localizations.dart';

import '../../domain/failures/business_review_failure.dart';

extension BusinessReviewTexts on AppLocalizations {
  String businessReviewFailureMessage(BusinessReviewFailureCode code) => switch (code) {
        BusinessReviewFailureCode.session => contactSessionChanged,
        BusinessReviewFailureCode.noPermission => reviewNoPermission,
        BusinessReviewFailureCode.mfaRequired => mfaSessionRequired,
        BusinessReviewFailureCode.alreadyReviewed => reviewAlreadyDone,
        BusinessReviewFailureCode.unavailable => reviewUnavailable,
        BusinessReviewFailureCode.reasonRequired => reviewReasonRequired,
        BusinessReviewFailureCode.documentMissing => businessReviewErrorDocumentMissing,
        BusinessReviewFailureCode.documentUnavailable => businessReviewErrorDocumentOpen,
        BusinessReviewFailureCode.ownerKaoIdRequired => businessReviewErrorOwnerKaoId,
        BusinessReviewFailureCode.ownerBankRequired => businessReviewErrorOwnerBank,
        BusinessReviewFailureCode.applicantInactive => businessReviewErrorApplicantInactive,
        BusinessReviewFailureCode.unknown => reviewActionFailed,
      };
}
