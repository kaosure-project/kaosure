import 'package:flutter/material.dart';

import '../../../kao_id/auth/presentation/pages/login_page.dart';
import '../../../kao_id/auth/presentation/pages/register_page.dart';

class LandingScreen extends StatelessWidget {
  static const String routeName = '/';

  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 100,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'KaoSure',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'ซื้อขายสินค้ามือสองอย่างมั่นใจ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 48),

                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        LoginPage.routeName,
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('เข้าสู่ระบบ'),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        RegisterPage.routeName,
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('สมัครสมาชิก'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}