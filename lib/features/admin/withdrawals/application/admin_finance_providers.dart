import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/admin_finance_service.dart';

final adminFinanceServiceProvider = Provider<AdminFinanceService>((ref) {
  return AdminFinanceService(Supabase.instance.client);
});

final staffToolsProvider = FutureProvider.autoDispose<Json?>((ref) {
  return ref.read(adminFinanceServiceProvider).staffTools();
});

final disputeQueueProvider =
    FutureProvider.autoDispose<List<Json>>((ref) {
  return ref.read(adminFinanceServiceProvider).loadDisputes();
});

final pendingWithdrawalsProvider =
    FutureProvider.autoDispose<List<Json>>((ref) {
  return ref.read(adminFinanceServiceProvider).loadPendingWithdrawals();
});

final adminFinanceActionsProvider = Provider<AdminFinanceActions>((ref) {
  return AdminFinanceActions(
    ref,
    ref.read(adminFinanceServiceProvider),
  );
});

class AdminFinanceActions {
  AdminFinanceActions(this._ref, this._service);

  final Ref _ref;
  final AdminFinanceService _service;

  Future<void> confirmDispute({
    required String issueId,
    required bool approve,
    String? reason,
  }) async {
    await _service.confirmDispute(
      issueId: issueId,
      approve: approve,
      reason: reason,
    );
    _ref.invalidate(disputeQueueProvider);
  }

  Future<void> approveWithdrawal(String id) async {
    await _service.approveWithdrawal(requestId: id);
    _ref.invalidate(pendingWithdrawalsProvider);
  }

  Future<void> payWithdrawal({
    required String id,
    required String reference,
  }) async {
    await _service.payWithdrawal(
      requestId: id,
      transferReference: reference,
    );
    _ref.invalidate(pendingWithdrawalsProvider);
  }
}