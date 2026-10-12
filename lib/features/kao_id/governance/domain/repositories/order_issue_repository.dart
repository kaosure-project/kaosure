import '../entities/order_issue_case.dart';

abstract class OrderIssueRepository {
  /// 30 per page; pass the last item's `sortAt` as [before].
  Future<List<OrderIssueCase>> queue(OrderIssueQueueFilter filter, {DateTime? before});

  /// With the order history and earlier reports on the same order.
  Future<OrderIssueCase> detail(String id);

  /// Needs a [note] both members see; refund and release move the money at once.
  Future<OrderIssueCase> resolve(String id, OrderIssueDecision decision, String note);
}
