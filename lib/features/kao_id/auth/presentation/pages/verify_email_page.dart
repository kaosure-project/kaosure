import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../application/providers/auth_provider.dart';
import '../../../../../app/routes/kao_id_routes.dart';
import '../widgets/auth_logo.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  static const String routeName = KaoIdRoutes.verifyEmail;

  const VerifyEmailPage({
    super.key,
  });

  @override
  ConsumerState<VerifyEmailPage> createState() =>
      _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _sending = false;
  bool _checking = false;

  Future<void> _sendEmail() async {
    if (_sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .resendEmailVerification();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authVerificationEmailSent,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authVerificationFailed,
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
    if (_checking) {
      return;
    }

    setState(() {
      _checking = true;
    });

    try {
      final user = await ref
          .read(authProvider.notifier)
          .refreshCurrentUser();

      if (!mounted) {
        return;
      }

      if (user?.emailConfirmed != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).authEmailNotVerified,
            ),
          ),
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authEmailVerified,
          ),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        KaoIdRoutes.bootstrap,
        (_) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authVerificationFailed,
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
    final authState = ref.watch(authProvider);
    final email = authState.value?.email ?? '-';

    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context).authVerifyEmail,
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

                      Text(
                        AppLocalizations.of(context).authVerifyEmail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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

                      Text(
                        AppLocalizations.of(context).authVerifyEmailInstructions,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(
                        height: AppSpacing.xxl,
                      ),

                      PrimaryButton(
                        text: AppLocalizations.of(context).authResendVerificationEmail,
                        icon: Icons.send,
                        isLoading: _sending,
                        onPressed: _sendEmail,
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      PrimaryButton(
                        text: AppLocalizations.of(context).authCheckAgain,
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
                            KaoIdRoutes.bootstrap,
                            (_) => false,
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context).authVerifyLater,
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