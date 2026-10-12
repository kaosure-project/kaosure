import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/forms/app_email_field.dart';
import '../../../../../shared/widgets/forms/app_password_field.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/kao_id_sso_handoff.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_continueExistingServiceSession());
    });
  }

  Future<void> _continueExistingServiceSession() async {
    if (!mounted || !kIsWeb) return;

    try {
      if (!await KaoIdSsoHandoff.hasPendingLoginReturn()) return;

      final user = await ref
          .read(authProvider.notifier)
          .refreshCurrentUser();
      if (user == null || !mounted) return;
    } catch (error, stackTrace) {
      debugPrint('Unable to restore existing Kao ID session: $error');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(KaoIdRoutes.bootstrap);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

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
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).authLoginFailed),
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
      return AppLocalizations.of(context).authEmailRequired;
    }

    final emailRegExp = RegExp(
      r'^[^@]+@[^@]+\.[^@]+$',
    );

    if (!emailRegExp.hasMatch(value.trim())) {
      return AppLocalizations.of(context).authEmailInvalid;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).authPasswordRequired;
    }

    if (value.runes.length < 8) {
      return AppLocalizations.of(context).authPasswordMinLength;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context).authLogin,
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
                          label: AppLocalizations.of(context).authEmail,
                          hint: AppLocalizations.of(context).authEmailHint,
                        ),

                        const SizedBox(
                          height: AppSpacing.md,
                        ),

                        AppPasswordField(
                          controller: _passwordController,
                          validator: _validatePassword,
                          onSubmitted: (_) => _login(),
                          label: AppLocalizations.of(context).password,
                          hint: AppLocalizations.of(context).authPasswordHint,
                        ),

                        const SizedBox(
                          height: AppSpacing.xl,
                        ),

                        PrimaryButton(
                          text: AppLocalizations.of(context).authLogin,
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
                          child: Text(
                            AppLocalizations.of(context).authForgotPasswordLink,
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              KaoIdRoutes.register,
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context).authRegister,
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
