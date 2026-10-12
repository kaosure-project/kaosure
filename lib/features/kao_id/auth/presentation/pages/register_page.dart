import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/forms/app_email_field.dart';
import '../../../../../shared/widgets/forms/app_password_field.dart';
import '../../application/providers/auth_provider.dart';
import '../../../../../app/routes/kao_id_routes.dart';
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
    if (_isLoading) return;

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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authRegistrationSucceeded,
          ),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        KaoIdRoutes.bootstrap,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).authRegistrationFailed),
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

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return AppLocalizations.of(context).authPasswordNumberRequired;
    }

    if (!RegExp(
      r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~`]',
    ).hasMatch(value)) {
      return AppLocalizations.of(context).authPasswordSpecialRequired;
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).authConfirmPasswordRequired;
    }

    if (value != _passwordController.text) {
      return AppLocalizations.of(context).authPasswordMismatch;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context).authCreateAccount,
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
                          label: AppLocalizations.of(context).authEmail,
                          hint: AppLocalizations.of(context).authEmailHint,
                        ),

                        const SizedBox(
                          height: AppSpacing.md,
                        ),

                        AppPasswordField(
                          controller: _passwordController,
                          validator: _validatePassword,
                          label: AppLocalizations.of(context).password,
                          hint: AppLocalizations.of(context).authPasswordHint,
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
                          label: AppLocalizations.of(context).authConfirmPassword,
                          hint: AppLocalizations.of(context).authConfirmPasswordHint,
                        ),

                        const SizedBox(
                          height: AppSpacing.xl,
                        ),

                        PrimaryButton(
                          text: AppLocalizations.of(context).authCreateAccount,
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
                          child: Text(
                            AppLocalizations.of(context).authExistingAccount,
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