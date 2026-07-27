import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/forms/app_email_field.dart';
import '../../../application/providers/auth_provider.dart';
import '../../router/kao_id_routes.dart';
import '../widgets/auth_logo.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  static const String routeName = KaoIdRoutes.forgotPassword;

  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).forgotPassword(
            _emailController.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ส่งลิงก์สำหรับรีเซ็ตรหัสผ่านไปยังอีเมลเรียบร้อยแล้ว',
          ),
        ),
      );

      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: 'ลืมรหัสผ่าน',
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
                          onSubmitted: (_) => _submit(),
                          label: 'อีเมล',
                          hint: 'กรอกอีเมล',
                        ),

                        const SizedBox(
                          height: AppSpacing.xl,
                        ),

                        PrimaryButton(
                          text: 'ส่งลิงก์รีเซ็ตรหัสผ่าน',
                          isLoading: _isLoading,
                          onPressed: _submit,
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