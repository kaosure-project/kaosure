import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/config/supabase_config.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/contact_change/domain/entities/contact_snapshot.dart';
import 'package:kaosure/features/kao_id/contact_change/domain/failures/contact_change_failure.dart';
import 'package:kaosure/features/kao_id/contact_change/domain/repositories/contact_change_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final contactChangeRepositoryProvider = Provider<ContactChangeRepository>((ref) {
  return SupabaseContactChangeRepository(ref.watch(supabaseClientProvider));
});

class SupabaseContactChangeRepository implements ContactChangeRepository {
  SupabaseContactChangeRepository(this.client);
  final SupabaseClient client;

  Future<User> _user(String? owner) async {
    final user = (await client.auth.getUser()).user;
    if (user == null || (owner != null && owner != user.id)) {
      throw const ContactChangeFailure('session');
    }
    return user;
  }

  List<String> _factors(User user) {
    final json = user.toJson();
    final factors = json['factors'] as List? ?? const [];
    return factors.whereType<Map>().where((f) =>
        f['status'] == 'verified' && f['factor_type'] == 'totp')
        .map((f) => f['id'] as String).toList();
  }

  @override
  Future<ContactSnapshot> read(ContactKind kind) async {
    final user = await _user(null);
    final json = user.toJson();
    final email = kind == ContactKind.email;
    final value = email ? (user.email ?? '') : (user.phone ?? '');
    var pending = json[email ? 'new_email' : 'new_phone'] as String? ?? '';
    if (!email && pending.isEmpty) {
      // A destination hint only; it never grants verified status.
      try {
        final preferences = await SharedPreferences.getInstance();
        pending = preferences.getString('kaoid.pending_phone.${user.id}') ?? '';
        if (pending.replaceFirst('+', '') == (user.phone ?? '').replaceFirst('+', '') &&
            user.phoneConfirmedAt != null) {
          await preferences.remove('kaoid.pending_phone.${user.id}');
          pending = '';
        }
      } catch (_) {
        // Storage is optional; authoritative status still comes from Auth.
      }
    }
    return ContactSnapshot(user.id,
      value.isEmpty ? '' : normalizeContact(kind, email ? value : '+${value.replaceFirst('+', '')}') ?? value,
      value.isNotEmpty && (email ? user.emailConfirmedAt != null : user.phoneConfirmedAt != null),
      pending.isEmpty ? '' : normalizeContact(kind, email ? pending : '+${pending.replaceFirst('+', '')}') ?? pending,
      factorIds: _factors(user));
  }

  @override
  Future<void> request(ContactKind kind, String owner, String target,
      String password, {required bool resend, String? factorId, String? code}) async {
    final user = await _user(owner);
    if (password.isEmpty) { throw const ContactChangeFailure('password'); }
    // Standalone client: never replace or persist the app's current session.
    final proof = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false, authFlowType: AuthFlowType.implicit));
    try {
      final result = await proof.auth.signInWithPassword(
        email: user.email?.isNotEmpty == true ? user.email : null,
        phone: user.email?.isNotEmpty == true ? null : user.phone,
        password: password);
      if (result.user?.id != owner || result.session == null) {
        throw const ContactChangeFailure('session');
      }
      final factors = _factors(result.user!);
      if (factors.isNotEmpty) {
        if (!factors.contains(factorId) || code == null || code.isEmpty) {
          throw const ContactChangeFailure('mfa');
        }
        await proof.auth.mfa.challengeAndVerify(factorId: factorId!, code: code);
      }
      await _user(owner);
      if (resend) {
        await proof.auth.resend(
          type: kind == ContactKind.email ? OtpType.emailChange : OtpType.phoneChange,
          email: kind == ContactKind.email ? target : null,
          phone: kind == ContactKind.phone ? target : null);
      } else {
        await proof.auth.updateUser(UserAttributes(
          email: kind == ContactKind.email ? target : null,
          phone: kind == ContactKind.phone ? target : null));
      }
      await _user(owner);
      if (kind == ContactKind.phone) {
        try {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setString('kaoid.pending_phone.$owner', target);
        } catch (_) {
          // The request succeeded even if the optional destination hint cannot be saved.
        }
      }
    } finally {
      try {
        if (proof.auth.currentSession != null) {
          await proof.auth.signOut(scope: SignOutScope.local);
        }
      } catch (_) {
        // Do not misreport a successfully submitted change as failed cleanup.
      }
      await proof.dispose();
    }
  }

  @override
  Future<void> verifyPhone(String owner, String target, String token) async {
    await _user(owner);
    await client.auth.verifyOTP(type: OtpType.phoneChange, phone: target, token: token);
    await _user(owner);
  }
}
