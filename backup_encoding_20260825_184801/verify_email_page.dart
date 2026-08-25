import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../router/kao_id_routes.dart';
import '../widgets/auth_logo.dart';

class VerifyEmailPage extends StatefulWidget {
  static const String routeName =
      KaoIdRoutes.verifyEmail;

  const VerifyEmailPage({
    super.key,
  });

  @override
  State<VerifyEmailPage> createState() =>
      _VerifyEmailPageState();
}

class _VerifyEmailPageState
    extends State<VerifyEmailPage> {
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
            'à¹„à¸¡à¹ˆà¸žà¸šà¸œà¸¹à¹‰à¹ƒà¸Šà¹‰à¸‡à¸²à¸™',
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
            'à¸ªà¹ˆà¸‡à¸­à¸µà¹€à¸¡à¸¥à¸¢à¸·à¸™à¸¢à¸±à¸™à¹€à¸£à¸µà¸¢à¸šà¸£à¹‰à¸­à¸¢à¹à¸¥à¹‰à¸§',
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
              'à¸¢à¸·à¸™à¸¢à¸±à¸™à¸­à¸µà¹€à¸¡à¸¥à¸ªà¸³à¹€à¸£à¹‡à¸ˆ',
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
            'à¸¢à¸±à¸‡à¹„à¸¡à¹ˆà¹„à¸”à¹‰à¸¢à¸·à¸™à¸¢à¸±à¸™à¸­à¸µà¹€à¸¡à¸¥',
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
    final email =
        _supabase.auth.currentUser?.email ??
            '-';

    return Scaffold(
      appBar: const AppAppBar(
        title: 'à¸¢à¸·à¸™à¸¢à¸±à¸™à¸­à¸µà¹€à¸¡à¸¥',
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
                  padding:
                      const EdgeInsets.all(
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
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
                        'à¸¢à¸·à¸™à¸¢à¸±à¸™à¸­à¸µà¹€à¸¡à¸¥',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      Text(
                        email,
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      const Text(
                        'à¸£à¸°à¸šà¸šà¹„à¸”à¹‰à¸ªà¹ˆà¸‡à¸­à¸µà¹€à¸¡à¸¥à¸¢à¸·à¸™à¸¢à¸±à¸™à¸šà¸±à¸à¸Šà¸µà¹à¸¥à¹‰à¸§\nà¸à¸£à¸¸à¸“à¸²à¹€à¸›à¸´à¸”à¸­à¸µà¹€à¸¡à¸¥à¹à¸¥à¸°à¸à¸”à¸¥à¸´à¸‡à¸à¹Œà¸¢à¸·à¸™à¸¢à¸±à¸™',
                        textAlign:
                            TextAlign.center,
                      ),

                      const SizedBox(
                        height: AppSpacing.xxl,
                      ),

                      PrimaryButton(
                        text:
                            'à¸ªà¹ˆà¸‡à¸­à¸µà¹€à¸¡à¸¥à¸¢à¸·à¸™à¸¢à¸±à¸™à¸­à¸µà¸à¸„à¸£à¸±à¹‰à¸‡',
                        icon: Icons.send,
                        isLoading:
                            _sending,
                        onPressed:
                            _sendEmail,
                      ),

                      const SizedBox(
                        height:
                            AppSpacing.md,
                      ),

                      PrimaryButton(
                        text:
                            'à¸•à¸£à¸§à¸ˆà¸ªà¸­à¸šà¸­à¸µà¸à¸„à¸£à¸±à¹‰à¸‡',
                        icon:
                            Icons.refresh,
                        isLoading:
                            _checking,
                        onPressed:
                            _checkVerification,
                      ),

                      const SizedBox(
                        height:
                            AppSpacing.md,
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            KaoIdRoutes
                                .login,
                            (_) => false,
                          );
                        },
                        child: const Text(
                          'à¸à¸¥à¸±à¸šà¹„à¸›à¹€à¸‚à¹‰à¸²à¸ªà¸¹à¹ˆà¸£à¸°à¸šà¸š',
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
