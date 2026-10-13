import 'dart:typed_data';

import 'package:kaosure/features/wallet/domain/entities/topup_request.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/topup_review.dart';
import '../../domain/repositories/topup_review_repository.dart';

/// `topup_queue/detail/review_r28` need `wallet.deposit.approve`; the settings
/// calls need `wallet.deposit.settings`. Reviews and saves also need a fresh
/// authenticator code when MFA is switched on.
class SupabaseTopupReviewRepository implements TopupReviewRepository {
  SupabaseTopupReviewRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<TopupReviewItem>> queue(TopupStatus status, {DateTime? before}) async {
    final rows = await _client.rpc<dynamic>(
      'topup_queue_r28',
      params: {'p_status': status.code, 'p_before': before?.toUtc().toIso8601String()},
    );
    return [
      if (rows is List)
        for (final row in rows) TopupReviewItem.fromJson(_map(row)),
    ];
  }

  @override
  Future<TopupReviewDetail> detail(String id) async =>
      TopupReviewDetail.fromJson(_map(await _client.rpc<dynamic>('topup_detail_r28', params: {'p_id': id})));

  @override
  Future<Uint8List> slip(String path) => _client.storage.from('wallet-slips').download(path);

  @override
  Future<TopupReviewItem> approve(String id, {required bool payerConfirmed, required String reference}) =>
      _review(id, approve: true, payerConfirmed: payerConfirmed, reference: reference);

  @override
  Future<TopupReviewItem> reject(String id, String reason) => _review(id, approve: false, reason: reason);

  Future<TopupReviewItem> _review(
    String id, {
    required bool approve,
    bool payerConfirmed = false,
    String? reference,
    String? reason,
  }) async => TopupReviewItem.fromJson(
    _map(
      await _client.rpc<dynamic>(
        'topup_review_r28',
        params: {
          'p_id': id,
          'p_approve': approve,
          'p_payer_confirmed': payerConfirmed,
          'p_reference': reference,
          'p_reason': reason,
        },
      ),
    ),
  );

  @override
  Future<TopupSettings> settings() async => TopupSettings.fromJson(_map(await _client.rpc<dynamic>('topup_settings_r28')));

  @override
  Future<TopupSettings> saveSettings(TopupSettings settings) async => TopupSettings.fromJson(
    _map(
      await _client.rpc<dynamic>(
        'topup_settings_save_r28',
        params: {
          'p_enabled': settings.enabled,
          'p_promptpay_type': settings.promptPayType?.code,
          'p_promptpay_id': settings.promptPayId,
          'p_receiver_name': settings.receiverName,
          'p_min': settings.minAmount,
          'p_max': settings.maxAmount,
          'p_daily': settings.dailyMax,
          'p_dual_from': settings.dualReviewFrom,
          'p_slip_hours': settings.slipHours,
          'p_version': settings.version,
        },
      ),
    ),
  );
}

Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
