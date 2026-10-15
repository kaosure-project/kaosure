import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_provider.dart';
import '../pages/login_page.dart';

class AuthGuard extends ConsumerStatefulWidget {
  final Widget authenticatedChild;

  const AuthGuard({
    super.key,
    required this.authenticatedChild,
  });

  @override
  ConsumerState<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends ConsumerState<AuthGuard> {
  String? _lastTrace;

  void _trace(String key, String message) {
    if (_lastTrace == key) return;
    _lastTrace = key;
    debugPrint('[OAuthFlow][AuthGuard] $message');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () {
        _trace('loading', 'state=loading action=wait');
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, _) {
        _trace(
          'error:${error.runtimeType}',
          'state=auth_error error_type=${error.runtimeType} '
              'action=show_login_fallback',
        );
        return const LoginPage();
      },
      data: (user) {
        if (user == null) {
          _trace('no_session', 'state=no_session action=show_login');
          return const LoginPage();
        }

        _trace('session_present', 'state=session_present action=show_protected_page');
        return widget.authenticatedChild;
      },
    );
  }
}
