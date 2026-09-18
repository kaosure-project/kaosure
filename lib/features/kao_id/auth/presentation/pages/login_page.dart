import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/forms/app_email_field.dart';
import '../../../../../shared/widgets/forms/app_password_field.dart';
import '../../application/providers/auth_provider.dart';
import '../../../router/kao_id_routes.dart';
import '../widgets/auth_logo.dart';

class LoginPage extends ConsumerStatefulWidget {
  static const String routeName = KaoIdRoutes.login;

  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        KaoIdRoutes.bootstrap,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกอีเมล';
    }

    final emailRegExp = RegExp(
      r'^[^@]+@[^@]+\.[^@]+$',
    );

    if (!emailRegExp.hasMatch(value.trim())) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }

    if (value.runes.length < 8) {
      return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: 'เข้าสู่ระบบ',
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(
                    AppSpacing.xl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthLogo(),

                        const SizedBox(
                          height: AppSpacing.xl,
                        ),

                        AppEmailField(
                          controller: _emailController,
                          validator: _validateEmail,
                          label: 'อีเมล',
                          hint: 'กรอกอีเมล',
                        ),

                        const SizedBox(
                          height: AppSpacing.md,
                        ),

                        AppPasswordField(
                          controller: _passwordController,
                          validator: _validatePassword,
                          onSubmitted: (_) => _login(),
                          label: 'รหัสผ่าน',
                          hint: 'กรอกรหัสผ่าน',
                        ),

                        const SizedBox(
                          height: AppSpacing.xl,
                        ),

                        PrimaryButton(
                          text: 'เข้าสู่ระบบ',
                          isLoading: _isLoading,
                          onPressed: _login,
                        ),

                        const SizedBox(
                          height: AppSpacing.md,
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              KaoIdRoutes.forgotPassword,
                            );
                          },
                          child: const Text(
                            'ลืมรหัสผ่าน?',
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              KaoIdRoutes.register,
                            );
                          },
                          child: const Text(
                            'สมัครสมาชิก',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}