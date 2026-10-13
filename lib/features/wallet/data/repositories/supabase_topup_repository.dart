import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/topup_request.dart';
import '../../domain/failures/topup_failure.dart';
import '../../domain/repositories/topup_repository.dart';

final topupRepositoryProvider = Provider<TopupRepository>(
  (ref) => SupabaseTopupRepository(ref.watch(supabaseClientProvider)),
);

/// Errors come back as [TopupFailure] with the server's code.
class SupabaseTopupRepository implements TopupRepository {
  SupabaseTopupRepository(this._client);

  static const bucket = 'wallet-slips';

  final SupabaseClient _client;

  @override
  Future<TopupInfo> info() async => TopupInfo.fromJson(_map(await _rpc('topup_info_r28')));

  @override
  Future<TopupRequest> create(double amount) async =>
      TopupRequest.fromJson(_map(await _rpc('topup_create_r28', {'p_amount': amount, 'p_source': 'kaoid'})));

  @override
  Future<TopupRequest> sendSlip(TopupRequest request, Uint8List jpeg) async {
    final user = _client.auth.currentUser?.id;
    if (user == null) throw const TopupFailure('authentication_required');
    Object? uploadError;
    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            '$user/${request.id}/slip.jpg',
            jpeg,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
          );
    } catch (e) {
      // A retry after a lost response finds the earlier upload already there.
      uploadError = e;
    }
    try {
      return TopupRequest.fromJson(_map(await _rpc('topup_attach_slip_r28', {'p_id': request.id})));
    } on TopupFailure catch (failure) {
      if (uploadError != null && failure.code == 'slip_required') throw TopupFailure(uploadFailureCode(uploadError));
      rethrow;
    }
  }

  @override
  Future<TopupRequest> cancel(String id) async =>
      TopupRequest.fromJson(_map(await _rpc('topup_cancel_r28', {'p_id': id})));

  @override
  Future<List<TopupRequest>> history({DateTime? before}) async {
    final rows = await _rpc('topup_history_r28', {'p_before': before?.toUtc().toIso8601String(), 'p_limit': 20});
    return [
      if (rows is List)
        for (final row in rows) TopupRequest.fromJson(_map(row)),
    ];
  }

  Future<Object?> _rpc(String name, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc<dynamic>(name, params: params);
    } on PostgrestException catch (e) {
      throw TopupFailure(RegExp(r'^[A-Za-z_]+$').hasMatch(e.message) ? e.message : 'failed');
    }
  }

  static String uploadFailureCode(Object error) {
    if (error is StorageException) {
      final status = error.statusCode ?? '';
      final message = error.message.toLowerCase();
      if (status == '413' || status == '415' || message.contains('size') || message.contains('mime')) {
        return 'slip_file';
      }
      if (status.startsWith('4')) return 'topup_not_open';
    }
    return 'upload_failed';
  }
}

Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
