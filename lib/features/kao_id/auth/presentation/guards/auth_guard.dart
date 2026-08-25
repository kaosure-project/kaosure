import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_provider.dart';
import '../pages/login_page.dart';

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
      error: (_, _) => const LoginPage(),
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }

        return authenticatedChild;
      },
    );
  }
}
