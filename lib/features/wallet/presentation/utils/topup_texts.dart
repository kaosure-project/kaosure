import 'package:intl/intl.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../domain/entities/topup_request.dart';
import '../../domain/failures/topup_failure.dart';

String topupBaht(double amount) => '฿${NumberFormat('#,##0.00').format(amount)}';

String topupStatusText(AppLocalizations l, TopupStatus status) => switch (status) {
  TopupStatus.awaitingSlip => l.topupStatusAwaitingSlip,
  TopupStatus.pendingReview => l.topupStatusPendingReview,
  TopupStatus.awaitingSecond => l.topupStatusAwaitingSecond,
  TopupStatus.approved => l.topupStatusApproved,
  TopupStatus.rejected => l.topupStatusRejected,
  TopupStatus.cancelled => l.topupStatusCancelled,
  TopupStatus.expired => l.topupStatusExpired,
};

String topupBlockText(AppLocalizations l, TopupBlock block) => switch (block) {
  TopupBlock.unavailable => l.topupBlockUnavailable,
  TopupBlock.kaoIdRequired => l.topupBlockKaoId,
  TopupBlock.walletUnavailable => l.topupBlockWallet,
  TopupBlock.requestOpen => l.topupErrorOpen,
  TopupBlock.dailyLimitReached => l.topupBlockDaily,
};

/// The member-facing text for a failed top-up step.
String topupErrorText(AppLocalizations l, Object error) {
  final code = error is TopupFailure ? error.code : '';
  return switch (code) {
    'amount_below_minimum' => l.topupErrorBelowMinimum,
    'amount_above_maximum' => l.topupErrorAboveMaximum,
    'invalid_amount' => l.topupErrorAmount,
    'topup_open' => l.topupErrorOpen,
    'daily_limit_reached' => l.topupBlockDaily,
    'topup_unavailable' => l.topupBlockUnavailable,
    'KAO_ID_REQUIRED' => l.topupBlockKaoId,
    'wallet_unavailable' => l.topupBlockWallet,
    'account_restricted' => l.restrictedAccountHelp,
    'slip_file' || 'invalid_slip' => l.topupErrorSlipFile,
    'slip_duplicate' => l.topupErrorSlipDuplicate,
    'topup_expired' => l.topupErrorExpired,
    'topup_not_open' || 'topup_not_cancellable' || 'topup_not_found' => l.topupErrorNotOpen,
    _ => l.topupErrorFailed,
  };
}
