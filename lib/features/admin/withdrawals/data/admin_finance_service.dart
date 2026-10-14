import 'package:supabase_flutter/supabase_flutter.dart';

typedef Json = Map<String, dynamic>;

List<Json> _rows(Object? value) {
  if (value is! List) {
    throw const FormatException('Expected a JSON array from Supabase');
  }

  return value
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
}

class AdminFinanceService {
  AdminFinanceService(this._client);

  final SupabaseClient _client;

  Future<List<Json>> loadDisputes({String filter = 'open'}) async {
    final result = await _client.rpc(
      'order_issue_queue_r26',
      params: {
        'p_filter': filter,
        'p_before': null,
      },
    );
    return _rows(result);
  }

  Future<List<Json>> loadPendingWithdrawals() async {
    final result = await _client.rpc(
      'withdrawal_queue_r24',
      params: {
        'p_status': 'pending',
        'p_before': null,
      },
    );
    return _rows(result);
  }

  Future<Json?> staffTools() async {
    final result = await _client.rpc('staff_tools_r24');
    return result == null
        ? null
        : Map<String, dynamic>.from(result as Map);
  }

  Future<void> proposeDispute({
    required String issueId,
    required String decision, // refund | release | dismiss
    required String note,
  }) async {
    await _client.rpc(
      'order_issue_resolve_r26',
      params: {
        'p_issue_id': issueId,
        'p_decision': decision,
        'p_note': note.trim(),
      },
    );
  }

  Future<void> confirmDispute({
    required String issueId,
    required bool approve,
    String? reason,
  }) async {
    await _client.rpc(
      'order_issue_confirm_r47b',
      params: {
        'p_issue_id': issueId,
        'p_approve': approve,
        'p_reason': reason?.trim(),
      },
    );
  }

  Future<void> withdrawDisputeProposal({
    required String issueId,
  }) async {
    await _client.rpc(
      'order_issue_withdraw_proposal_r47b',
      params: {'p_issue_id': issueId},
    );
  }

  Future<void> approveWithdrawal({
    required String requestId,
  }) async {
    await _client.rpc(
      'withdrawal_approve_r47b',
      params: {'p_id': requestId},
    );
  }

  Future<void> payWithdrawal({
    required String requestId,
    required String transferReference,
  }) async {
    await _client.rpc(
      'withdrawal_review_r24',
      params: {
        'p_id': requestId,
        'p_paid': true,
        'p_reference': transferReference.trim(),
        'p_reason': null,
      },
    );
  }

  Future<void> rejectWithdrawal({
    required String requestId,
    required String reason,
  }) async {
    await _client.rpc(
      'withdrawal_review_r24',
      params: {
        'p_id': requestId,
        'p_paid': false,
        'p_reference': null,
        'p_reason': reason.trim(),
      },
    );
  }
}