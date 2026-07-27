import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/auth_provider.dart';
import '../screens/login_screen.dart';

class AuthGuard extends ConsumerWidget {
  final Widget authenticatedChild;

  const AuthGuard({
    super.key,
    required this.authenticatedChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const LoginScreen(),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        return authenticatedChild;
      },
    );
  }
}