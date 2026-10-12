import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/staff_tools.dart';
import '../../domain/entities/withdrawal_request.dart';
import '../../domain/repositories/withdrawal_review_repository.dart';

/// `staff_tools_r24` and `withdrawal_*_r24`. Each call checks the
/// `wallet.withdraw.approve` permission on the server; paying and rejecting
/// also need a fresh authenticator code when MFA is switched on.
class SupabaseWithdrawalReviewRepository implements WithdrawalReviewRepository {
  SupabaseWithdrawalReviewRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<StaffTools> tools() async => StaffTools.fromJson(_map(await _client.rpc<dynamic>('staff_tools_r24')));

  @override
  Future<List<WithdrawalRequest>> queue(WithdrawalStatus status, {DateTime? before}) async {
    final rows = await _client.rpc<dynamic>(
      'withdrawal_queue_r24',
      params: {'p_status': status.name, 'p_before': before?.toUtc().toIso8601String()},
    );
    return [
      if (rows is List)
        for (final row in rows) WithdrawalRequest.fromJson(_map(row)),
    ];
  }

  @override
  Future<WithdrawalTransfer> detail(String id) async =>
      WithdrawalTransfer.fromJson(_map(await _client.rpc<dynamic>('withdrawal_detail_r24', params: {'p_id': id})));

  @override
  Future<WithdrawalRequest> markPaid(String id, String reference) => _review(id, paid: true, reference: reference);

  @override
  Future<WithdrawalRequest> reject(String id, String reason) => _review(id, paid: false, reason: reason);

  Future<WithdrawalRequest> _review(String id, {required bool paid, String? reference, String? reason}) async =>
      WithdrawalRequest.fromJson(
        _map(
          await _client.rpc<dynamic>(
            'withdrawal_review_r24',
            params: {'p_id': id, 'p_paid': paid, 'p_reference': reference, 'p_reason': reason},
          ),
        ),
      );
}

Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
