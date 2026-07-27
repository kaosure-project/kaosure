import 'package:flutter/material.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_text_styles.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../router/kao_id_routes.dart';
import '../widgets/auth_logo.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const routeName = KaoIdRoutes.landing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                      PrimaryButton(
                        text: 'Sign In',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            KaoIdRoutes.login,
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      SecondaryButton(
                        text: 'Create Account',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            KaoIdRoutes.register,
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      const Divider(),

                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Kao ID v1.0.0',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall,
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