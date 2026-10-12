import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/forms/app_password_field.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/providers/password_recovery_provider.dart';
import '../../../../../app/routes/kao_id_routes.dart';
import '../widgets/auth_logo.dart';
import '../widgets/password_requirements.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  static const String routeName = KaoIdRoutes.resetPassword;

  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState
    extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(_refreshPasswordState);
    _confirmPasswordController.addListener(_refreshPasswordState);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refreshPasswordState);
    _confirmPasswordController.removeListener(_refreshPasswordState);

    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _refreshPasswordState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }

    final isRecoveryAuthorized = ref.read(
      passwordRecoveryAuthorizedProvider,
    );

    if (!isRecoveryAuthorized) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).updatePassword(
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      ref
          .read(passwordRecoveryAuthorizedProvider.notifier)
          .state = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authPasswordChanged,
          ),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil(
        KaoIdRoutes.login,
        (route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).authResetFailed),
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).authNewPasswordRequired;
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
      return AppLocalizations.of(context).authConfirmNewPasswordRequired;
    }

    if (value != _passwordController.text) {
      return AppLocalizations.of(context).authPasswordMismatch;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isRecoveryAuthorized = ref.watch(
      passwordRecoveryAuthorizedProvider,
    );

    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context).authResetPassword,
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
              child: isRecoveryAuthorized
                  ? _buildResetPasswordForm()
                  : _buildInvalidRecoveryState(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetPasswordForm() {
    return AppCard(
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

              AppPasswordField(
                controller: _passwordController,
                validator: _validatePassword,
                label: AppLocalizations.of(context).authNewPassword,
                hint: AppLocalizations.of(context).authNewPasswordHint,
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
                controller: _confirmPasswordController,
                validator: _validateConfirmPassword,
                label: AppLocalizations.of(context).authConfirmNewPassword,
                hint: AppLocalizations.of(context).authConfirmNewPasswordHint,
              ),

              const SizedBox(
                height: AppSpacing.xl,
              ),

              PrimaryButton(
                text: AppLocalizations.of(context).changePassword,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvalidRecoveryState() {
    return AppCard(
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
              Icons.link_off_rounded,
              size: 48,
            ),

            const SizedBox(
              height: AppSpacing.md,
            ),

            Text(
              AppLocalizations.of(context).authInvalidRecoveryLink,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(
              height: AppSpacing.sm,
            ),

            Text(
              AppLocalizations.of(context).authInvalidRecoveryDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(
              height: AppSpacing.xl,
            ),

            PrimaryButton(
              text: AppLocalizations.of(context).authRequestNewLink,
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(
                  KaoIdRoutes.forgotPassword,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}