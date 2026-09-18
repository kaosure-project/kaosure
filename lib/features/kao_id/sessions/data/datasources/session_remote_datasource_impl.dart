import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/session_model.dart';
import 'session_remote_datasource.dart';

final class SessionRemoteDataSourceImpl
    implements SessionRemoteDataSource {
  SessionRemoteDataSourceImpl({
    required this._supabase,
  });

  final SupabaseClient _supabase;

  static const String _table = 'sessions';

  @override
  Future<List<SessionModel>> getSessions({
    required String ownerId,
  }) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('profile_id', ownerId)
        .order(
          'created_at',
          ascending: false,
        );

    return response
        .map(
          (row) => SessionModel.fromJson(row),
        )
        .toList(growable: false);
  }

  @override
  Future<SessionModel?> getSession({
    required String sessionId,
  }) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return SessionModel.fromJson(response);
  }

  @override
  Future<void> createSession({
    required SessionModel session,
  }) async {
    await _supabase
        .from(_table)
        .insert(session.toJson());
  }

  @override
  Future<void> updateSession({
    required SessionModel session,
  }) async {
    await _supabase
        .from(_table)
        .update({
          'device_id': session.deviceId,
          'token_type': session.tokenType,
          'platform': session.platform,
          'ip_address': session.ipAddress,
          'user_agent': session.userAgent,
          'country': session.country,
          'city': session.city,
          'last_activity_at':
              session.lastActivityAt.toIso8601String(),
          'expires_at':
              session.expiresAt.toIso8601String(),
          'revoked_at':
              session.revokedAt?.toIso8601String(),
        })
        .eq('id', session.id)
        .eq('profile_id', session.ownerId);
  }

  @override
  Future<void> revokeSession({
    required String sessionId,
  }) async {
    await _supabase
        .from(_table)
        .update({
          'revoked_at':
              DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }

  @override
  Future<void> revokeAllSessions({
    required String ownerId,
  }) async {
    await _supabase
        .from(_table)
        .update({
          'revoked_at':
              DateTime.now().toIso8601String(),
        })
        .eq('profile_id', ownerId)
        .isFilter('revoked_at', null);
  }

  @override
  Future<bool> exists({
    required String sessionId,
  }) async {
    final response = await _supabase
        .from(_table)
        .select('id')
        .eq('id', sessionId)
        .maybeSingle();

    return response != null;
  }
}