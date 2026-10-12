import 'package:kaosure/l10n/app_localizations.dart';
import '../../application/states/kyc_state.dart';
import '../../domain/entities/kyc_identity_document.dart';
import 'kyc_status_label.dart';

/// A summary flag is not evidence that a document exists or was approved.
String documentStatusLabel(AppLocalizations l, KycState state,
    KycIdentityDocument? document) {
  if (!state.isAvailable(KycResource.documents)) {
    return l.kycUnknownStatus;
  }
  return document == null ? l.kycNoDocumentSubmitted
      : kycStatusLabel(l, document.status);
}
