import '../../governance/members/member_repository.dart';
import '../../kyc/review/kyc_review_repository.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../auth/application/providers/auth_provider.dart';
import '../../auth/presentation/pages/reset_password_page.dart';
import 'lifecycle_page.dart';

abstract class AccountAccessRepository {
  String? get userId;
  Stream<void> get changes;
  Future<String> check();
  Future<void> signOut();
}
final accountAccessRepositoryProvider = Provider<AccountAccessRepository>((ref) =>
    _AccountAccessRepository(ref.read(supabaseClientProvider)));
class _AccountAccessRepository implements AccountAccessRepository {
  _AccountAccessRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  Stream<void> get changes => client.auth.onAuthStateChange.map((_) {});
  @override
  Future<String> check() async =>
      (await client.rpc('account_access_r10d') as Map)['state'] as String;
  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}

/// The server enforces closure; this gate hides stale screens and explains it.
class AccountAccessGate extends ConsumerStatefulWidget {
  const AccountAccessGate({super.key, required this.child, required this.navigatorKey});
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  @override
  ConsumerState<AccountAccessGate> createState() => _AccountAccessGateState();
}
class _AccountAccessGateState extends ConsumerState<AccountAccessGate>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _subscription;
  Timer? _timer;
  String? _user;
  String _state = 'loading';
  int _generation = 0;
  bool _checking = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = ref.read(accountAccessRepositoryProvider).changes.listen((_) {
      // Immediately hide a previous user's screen; discard any in-flight response.
      _generation++;
      _checking = false;
      if (mounted && ref.read(accountAccessRepositoryProvider).userId != _user) {
        setState(() => _state = 'loading');
      }
      unawaited(_check());
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
    unawaited(_check());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { unawaited(_check()); }
  }
  Future<void> _check() async {
    if (!mounted || _checking) { return; }
    final repository = ref.read(accountAccessRepositoryProvider);
    final user = repository.userId;
    final generation = ++_generation;
    _checking = true;
    try {
      final result = user == null ? 'signed_out' :
          await repository.check().timeout(const Duration(seconds: 12));
      if (!mounted || generation != _generation || repository.userId != user) { return; }
      setState(() {
        _user = user;
        _state = ['active', 'closed', 'session_revoked', 'signed_out', 'suspended', 'banned', 'temporarily_locked', 'unavailable'].contains(result)
            ? result : 'error';
      });
      // Refresh subscribed menus after the authoritative account/session check.
      ref.invalidate(memberAccessProvider);
      ref.invalidate(kycReviewerAccessProvider);
    } catch (_) {
      if (mounted && generation == _generation) { setState(() => _state = 'error'); }
    } finally {
      if (generation == _generation) { _checking = false; }
    }
  }
  Future<void> _signOut() async {
    try {
      await ref.read(accountAccessRepositoryProvider).signOut();
      if (!mounted) { return; }
      await ref.read(authProvider.notifier).loadCurrentUser();
      await _check();
    } catch (_) {
      if (mounted) { setState(() => _state = 'error'); }
    }
  }
  @override
  void dispose() {
    _generation++;
    _subscription?.cancel(); _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (_state == 'active' || _state == 'signed_out') { return widget.child; }
    if (_state == 'loading') {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // A separate navigator prevents old protected routes from surviving closure.
    // App directs password-reset links to this navigator while access is limited.
    // No protected route is reachable from this restricted navigator.
    return Navigator(key: widget.navigatorKey,
      pages: [MaterialPage<void>(key: ValueKey('$_state:$_user'), child: Builder(builder: _restrictedPage))],
      onDidRemovePage: (_) {},
      onGenerateRoute: (settings) {
        if (settings.name == ResetPasswordPage.routeName) {
          return MaterialPageRoute<void>(settings: settings, builder: (_) => const ResetPasswordPage());
        }
        return MaterialPageRoute<void>(settings: settings, builder: _restrictedPage);
      });
  }
  Widget _restrictedPage(BuildContext context) {
        final l = AppLocalizations.of(context);
        final closed = _state == 'closed';
        return Scaffold(appBar: AppBar(title: Text(closed ? l.closeAccountTitle : l.accountStateTitle)), body: SafeArea(
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Icon(closed ? Icons.lock_outline : Icons.info_outline, size: 48),
              const SizedBox(height: 20),
              Text(closed ? l.closeAccountHelp : _state == 'session_revoked'
                  ? l.closeSessionEnded : ['suspended', 'banned', 'temporarily_locked'].contains(_state)
                  ? l.restrictedAccountHelp : _state == 'unavailable' ? l.unavailableAccountHelp : l.kycLoadFailed),
              const SizedBox(height: 20),
              if (closed) FilledButton(onPressed: () async {
                await ref.read(authProvider.notifier).loadCurrentUser();
                if (!context.mounted || _state != 'closed' ||
                    ref.read(accountAccessRepositoryProvider).userId != _user) { return; }
                await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LifecyclePage()));
              }, child: Text(l.lifeRecover)),
              OutlinedButton(onPressed: _check, child: Text(l.authCheckAgain)),
              TextButton(onPressed: _signOut, child: Text(l.signOut)),
            ])))));
  }
}
