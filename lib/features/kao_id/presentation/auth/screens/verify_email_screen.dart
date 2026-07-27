import 'package:flutter/material.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../router/kao_id_routes.dart';
import '../widgets/auth_logo.dart';

class VerifyEmailScreen extends StatelessWidget {
  static const String routeName = KaoIdRoutes.verifyEmail;

  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: 'ยืนยันอีเมล',
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthLogo(),

                      const SizedBox(height: AppSpacing.xl),

                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 72,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      const Text(
                        'ยืนยันอีเมล',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      const Text(
                        'เราได้ส่งอีเมลสำหรับยืนยันบัญชีไปยังอีเมลของคุณแล้ว\n\n'
                        'กรุณาเปิดอีเมลและกดลิงก์ยืนยันบัญชี จากนั้นจึงเข้าสู่ระบบเพื่อใช้งาน KaoSure',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      PrimaryButton(
                        text: 'กลับไปเข้าสู่ระบบ',
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            KaoIdRoutes.login,
                            (_) => false,
                          );
                        },
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