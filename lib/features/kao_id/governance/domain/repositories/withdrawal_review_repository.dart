import '../entities/staff_tools.dart';
import '../entities/withdrawal_request.dart';

abstract class WithdrawalReviewRepository {
  Future<StaffTools> tools();

  /// Newest first, 30 per page.
  Future<List<WithdrawalRequest>> queue(WithdrawalStatus status, {DateTime? before});

  Future<WithdrawalTransfer> detail(String id);

  /// After the money was sent from the company account.
  Future<WithdrawalRequest> markPaid(String id, String reference);

  /// Returns the amount to the member's wallet.
  Future<WithdrawalRequest> reject(String id, String reason);
}
