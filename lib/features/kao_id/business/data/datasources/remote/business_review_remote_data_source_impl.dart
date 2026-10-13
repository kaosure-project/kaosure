import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'business_review_remote_data_source.dart';

final class BusinessReviewRemoteDataSourceImpl implements BusinessReviewRemoteDataSource {
  BusinessReviewRemoteDataSourceImpl({required this._supabase});

  static const _documentBucket = 'identity-documents';
  static const _linkLifetimeSeconds = 120;

  final SupabaseClient _supabase;

  @override
  String? currentUserId() => _supabase.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> queue() async {
    final response = await _supabase.rpc('business_review_queue_r15b');
    return [
      for (final row in response as List? ?? const [])
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  @override
  Future<Uint8List> download(String path) => _supabase.storage.from(_documentBucket).download(path);

  @override
  Future<String> signedUrl(String path) =>
      _supabase.storage.from(_documentBucket).createSignedUrl(path, _linkLifetimeSeconds);

  @override
  Future<String> decide({
    required String expectedUserId,
    required String registrationId,
    required bool approve,
    required bool directorConfirmed,
    String? reason,
  }) async {
    final response = await _supabase.rpc(
      'business_review_decide_r27c',
      params: {
        'p_expected_user': expectedUserId,
        'p_registration': registrationId,
        'p_approve': approve,
        'p_reason': reason,
        'p_director_confirmed': directorConfirmed,
      },
    );
    if (response is Map && response['status'] is String) {
      return response['status'] as String;
    }
    throw StateError('Invalid business review response: ${response.runtimeType}');
  }
}
