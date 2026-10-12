import 'package:kaosure/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/personal_info.dart';
import '../../domain/entities/sensitive_field.dart';
import '../../domain/repositories/personal_info_repository.dart';
import '../models/personal_info_model.dart';

/// The server accepts a password proof for 5 minutes; stop using it a little earlier.
const _grantLifetime = Duration(minutes: 4, seconds: 30);

final class _ProofGrant extends RevealGrant {
  _ProofGrant(this.client, this.owner) : expiresAt = DateTime.now().add(_grantLifetime);

  /// Standalone client holding the password-proven session; never the app's own session.
  final SupabaseClient client;
  final String owner;
  @override
  final DateTime expiresAt;
}

class SupabasePersonalInfoRepository implements PersonalInfoRepository {
  SupabasePersonalInfoRepository(this.client);
  final SupabaseClient client;

  String _owner() {
    final id = client.auth.currentUser?.id;
    if (id == null) throw const PersonalInfoFailure('session');
    return id;
  }

  PersonalInfoFailure _failure(Object error, String fallback) {
    final message = switch (error) {
      PostgrestException(:final message) => message,
      AuthException(:final message) => message,
      _ => '',
    };
    for (final code in const ['password_required', 'rate_limited', 'not_found', 'session_required']) {
      if (message.contains(code)) {
        return PersonalInfoFailure(switch (code) {
          'password_required' => 'password',
          'session_required' => 'session',
          _ => code,
        });
      }
    }
    return PersonalInfoFailure(fallback);
  }

  @override
  Future<PersonalInfo> load() async {
    final owner = _owner();
    try {
      final result = await client.rpc('my_personal_info_r16a');
      if (_owner() != owner || result is! Map) throw const PersonalInfoFailure('session');
      return PersonalInfoModel.fromJson(Map<String, dynamic>.from(result));
    } on PersonalInfoFailure {
      rethrow;
    } catch (error) {
      throw _failure(error, 'load');
    }
  }

  @override
  Future<RevealGrant> unlock(String password) async {
    final user = client.auth.currentUser;
    if (user == null) throw const PersonalInfoFailure('session');
    if (password.isEmpty) throw const PersonalInfoFailure('password');
    final email = user.email?.isNotEmpty == true ? user.email : null;
    final proof = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false, authFlowType: AuthFlowType.implicit));
    try {
      final result = await proof.auth.signInWithPassword(
        email: email, phone: email == null ? user.phone : null, password: password);
      if (result.user?.id != user.id || result.session == null || _owner() != user.id) {
        throw const PersonalInfoFailure('session');
      }
      return _ProofGrant(proof, user.id);
    } catch (error) {
      await _dispose(proof);
      if (error is PersonalInfoFailure) rethrow;
      if (error is AuthException) throw const PersonalInfoFailure('password');
      throw _failure(error, 'reveal');
    }
  }

  @override
  Future<String> reveal(RevealGrant grant, SensitiveField field) async {
    if (grant is! _ProofGrant || !grant.isActive) throw const PersonalInfoFailure('password');
    if (_owner() != grant.owner) throw const PersonalInfoFailure('session');
    try {
      final value = await grant.client.rpc('reveal_my_personal_field_r16a',
        params: {'p_field': field.code});
      if (value is! String || value.isEmpty) throw const PersonalInfoFailure('not_found');
      return value;
    } on PersonalInfoFailure {
      rethrow;
    } catch (error) {
      throw _failure(error, 'reveal');
    }
  }

  @override
  Future<void> release(RevealGrant grant) async {
    if (grant is _ProofGrant) await _dispose(grant.client);
  }

  Future<void> _dispose(SupabaseClient proof) async {
    try {
      if (proof.auth.currentSession != null) {
        await proof.auth.signOut(scope: SignOutScope.local);
      }
    } catch (_) {
      // The proof session expires on its own; cleanup failure must not surface to the user.
    }
    await proof.dispose();
  }
}
