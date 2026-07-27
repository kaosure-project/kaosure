import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/session_model.dart';
import 'session_remote_datasource.dart';

final class SessionRemoteDataSourceImpl
    implements SessionRemoteDataSource {
  SessionRemoteDataSourceImpl({
    required SupabaseClient supabase,
  }) : _supabase = supabase;

  final SupabaseClient _supabase;

  @override
  Future<List<SessionModel>> getSessions({
    required String ownerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SessionModel?> getSession({
    required String sessionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> createSession({
    required SessionModel session,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateSession({
    required SessionModel session,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> revokeSession({
    required String sessionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> revokeAllSessions({
    required String ownerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> exists({
    required String sessionId,
  }) {
    throw UnimplementedError();
  }
}