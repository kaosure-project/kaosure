import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../router/kao_id_routes.dart';
import '../widgets/auth_logo.dart';

class VerifyEmailPage extends StatefulWidget {
  static const String routeName = KaoIdRoutes.verifyEmail;

  const VerifyEmailPage({
    super.key,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _supabase = Supabase.instance.client;

  bool _sending = false;
  bool _checking = false;

  Future<void> _sendEmail() async {
    final user = _supabase.auth.currentUser;

    if (user == null || user.email == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ไม่พบผู้ใช้งาน',
          ),
        ),
      );

      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ส่งอีเมลยืนยันเรียบร้อยแล้ว',
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
    });

    try {
      await _supabase.auth.refreshSession();

      final user = _supabase.auth.currentUser;

      if (!mounted) {
        return;
      }

      if (user?.emailConfirmedAt != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ยืนยันอีเมลสำเร็จ',
            ),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          KaoIdRoutes.login,
          (_) => false,
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ยังไม่ได้ยืนยันอีเมล',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _supabase.auth.currentUser?.email ?? '-';

    return Scaffold(
      appBar: const AppAppBar(
        title: 'ยืนยันอีเมล',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthLogo(),

                      const SizedBox(
                        height: AppSpacing.xl,
                      ),

                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 72,
                        color: Colors.blue,
                      ),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      const Text(
                        'ยืนยันอีเมล',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      const Text(
                        'ระบบได้ส่งอีเมลยืนยันบัญชีแล้ว\n'
                        'กรุณาเปิดอีเมลและกดลิงก์ยืนยัน',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(
                        height: AppSpacing.xxl,
                      ),

                      PrimaryButton(
                        text: 'ส่งอีเมลยืนยันอีกครั้ง',
                        icon: Icons.send,
                        isLoading: _sending,
                        onPressed: _sendEmail,
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      PrimaryButton(
                        text: 'ตรวจสอบอีกครั้ง',
                        icon: Icons.refresh,
                        isLoading: _checking,
                        onPressed: _checkVerification,
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            KaoIdRoutes.login,
                            (_) => false,
                          );
                        },
                        child: const Text(
                          'กลับไปเข้าสู่ระบบ',
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
    );
  }
}