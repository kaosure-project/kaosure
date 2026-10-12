import 'package:kaosure/l10n/app_localizations.dart';

String kycStatusLabel(AppLocalizations l10n, String? status) {
  return switch (status) {
    'approved' || 'verified' || 'completed' || 'complete' => l10n.kycVerifiedStatus,
    'manual_review' || 'pending_review' || 'pending' || 'submitted' || 'reviewing' || 'under_review' => l10n.kycPendingStatus,
    'rejected' => l10n.kycRejectedStatus,
    'revoked' => l10n.documentRevoked,
    'expired' => l10n.kycExpiredStatus,
    'cancelled' => l10n.kycCancelledStatus,
    'not_started' || 'draft' || 'unverified' => l10n.kycUnverifiedStatus,
    _ => l10n.kycUnknownStatus,
  };
}
