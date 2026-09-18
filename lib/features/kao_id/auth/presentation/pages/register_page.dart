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
import '../widgets/password_requirements.dart';

class RegisterPage extends ConsumerStatefulWidget {
  static const String routeName = KaoIdRoutes.register;

  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(() {
      setState(() {});
    });

    _confirmPasswordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'สมัครสมาชิกสำเร็จ กรุณาตรวจสอบอีเมลเพื่อยืนยันบัญชี',
          ),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        KaoIdRoutes.verifyEmail,
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

  void _openBusinessRegistration() {
    Navigator.of(context).pushNamed(
      '/kao-id/business/register',
    );
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

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว';
    }

    if (!RegExp(
      r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~`]',
    ).hasMatch(value)) {
      return 'รหัสผ่านต้องมีอักขระพิเศษอย่างน้อย 1 ตัว';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณายืนยันรหัสผ่าน';
    }

    if (value != _passwordController.text) {
      return 'รหัสผ่านไม่ตรงกัน';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: 'สร้างบัญชี',
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
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
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
                          label: 'รหัสผ่าน',
                          hint: 'กรอกรหัสผ่าน',
                        ),

                        const SizedBox(
                          height: AppSpacing.sm,
                        ),

                        PasswordRequirements(
                          password: _passwordController.text,
                        ),

                        const SizedBox(
                          height: AppSpacing.md,
                        ),

                        AppPasswordField(
                          controller:
                              _confirmPasswordController,
                          validator:
                              _validateConfirmPassword,
                          label: 'ยืนยันรหัสผ่าน',
                          hint: 'กรอกรหัสผ่านอีกครั้ง',
                        ),

                        const SizedBox(
                          height: AppSpacing.xl,
                        ),

                        PrimaryButton(
                          text: 'สร้างบัญชี',
                          isLoading: _isLoading,
                          onPressed: _register,
                        ),

                        const SizedBox(
                          height: AppSpacing.md,
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                          ),
                        ),

                        const SizedBox(
                          height: AppSpacing.sm,
                        ),

                        const Divider(),

                        const SizedBox(
                          height: AppSpacing.sm,
                        ),

                        TextButton.icon(
                          onPressed:
                              _openBusinessRegistration,
                          icon: const Icon(
                            Icons.business_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'สมัครในนามบริษัท / ผู้ประกอบการ',
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