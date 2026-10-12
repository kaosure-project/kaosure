import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';

abstract interface class MfaRepository {
  Future<Map<String, dynamic>> load();
  Future<Map<String, String>> enroll(String name, String password);
  Future<void> verify(String factor, String code);
  Future<void> cancelEnrollment(String factor);
  Future<void> enablePolicy();
}
final mfaRepositoryProvider = Provider<MfaRepository>((ref) =>
    SupabaseMfaRepository(ref.watch(supabaseClientProvider)));
class SupabaseMfaRepository implements MfaRepository {
  SupabaseMfaRepository(this.client);
  final SupabaseClient client;
  String _user() {
    final id = client.auth.currentUser?.id;
    if (id == null) { throw StateError('session'); }
    return id;
  }
  void _check(String id) { if (_user() != id) { throw StateError('session'); } }
  @override
  Future<Map<String, dynamic>> load() async {
    final id = _user();
    final factors = await client.auth.mfa.listFactors();
    _check(id);
    final status = Map<String, dynamic>.from(await client.rpc('security_status_r14a') as Map);
    _check(id);
    return {...status, 'factors': [for (final f in factors.totp)
      {'id': f.id, 'name': f.friendlyName ?? '—'}]};
  }
  @override
  Future<Map<String, String>> enroll(String name, String password) async {
    final id = _user();
    final factors = await client.auth.mfa.listFactors();
    _check(id);
    if (factors.all.every((f) => f.status != FactorStatus.verified)) {
      final email = client.auth.currentUser?.email;
      if (email == null || password.isEmpty) { throw StateError('password_required'); }
      await client.auth.signInWithPassword(email: email, password: password);
      _check(id);
    }
    final result = await client.auth.mfa.enroll(
      factorType: FactorType.totp, issuer: 'Kao ID', friendlyName: name.trim());
    _check(id);
    return {'id': result.id, 'secret': result.totp!.secret};
  }
  @override
  Future<void> verify(String factor, String code) async {
    final id = _user();
    await client.auth.mfa.challengeAndVerify(factorId: factor, code: code.trim());
    _check(id);
  }
  @override
  Future<void> cancelEnrollment(String factor) async {
    final id = _user();
    final factors = await client.auth.mfa.listFactors();
    _check(id);
    if (factors.all.any((f) => f.id == factor && f.status == FactorStatus.verified)) {
      throw StateError('verified_factor_protected');
    }
    await client.auth.mfa.unenroll(factor);
    _check(id);
  }
  @override
  Future<void> enablePolicy() async {
    final id = _user();
    await client.rpc('enable_security_r14a', params: {'p_expected_user': id});
    _check(id);
  }
}
