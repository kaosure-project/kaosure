import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/order_issue_case.dart';
import '../../domain/repositories/order_issue_repository.dart';

/// `order_issue_*_r26`. Each call checks `marketplace.orders.resolve` on the
/// server; deciding also needs a fresh authenticator code when MFA is on.
class SupabaseOrderIssueRepository implements OrderIssueRepository {
  SupabaseOrderIssueRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<OrderIssueCase>> queue(OrderIssueQueueFilter filter, {DateTime? before}) async {
    final rows = await _client.rpc<dynamic>(
      'order_issue_queue_r26',
      params: {'p_filter': filter.name, 'p_before': before?.toUtc().toIso8601String()},
    );
    return [
      if (rows is List)
        for (final row in rows) OrderIssueCase.fromJson(_map(row)),
    ];
  }

  @override
  Future<OrderIssueCase> detail(String id) async =>
      OrderIssueCase.fromJson(_map(await _client.rpc<dynamic>('order_issue_detail_r26', params: {'p_issue_id': id})));

  @override
  Future<OrderIssueCase> resolve(String id, OrderIssueDecision decision, String note) async => OrderIssueCase.fromJson(
    _map(
      await _client.rpc<dynamic>(
        'order_issue_resolve_r26',
        params: {'p_issue_id': id, 'p_decision': decision.name, 'p_note': note},
      ),
    ),
  );
}

Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
