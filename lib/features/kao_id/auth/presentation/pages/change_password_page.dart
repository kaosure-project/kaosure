import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/design_system/spacing/app_spacing.dart';
import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';
import '../../../../../shared/widgets/forms/app_password_field.dart';
import '../../../../../shared/widgets/forms/app_text_field.dart';
import '../../application/providers/auth_provider.dart';
import '../../../../../app/routes/kao_id_routes.dart';
import '../widgets/password_requirements.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  static const String routeName = KaoIdRoutes.changePassword;

  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _nonceController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSendingCode = false;
  bool _isChangingPassword = false;
  bool _codeSent = false;

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

    _nonceController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _refreshPasswordState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _sendReauthenticationCode() async {
    if (_isSendingCode) {
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      await ref.read(authProvider.notifier).reauthenticate();

      if (!mounted) {
        return;
      }

      _nonceController.clear();

      setState(() {
        _codeSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authVerificationCodeSent,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Password reauthentication failed: $error',
      );
      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authSendCodeFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_isChangingPassword || !_codeSent) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      await ref.read(authProvider.notifier).changePassword(
            currentPassword: _currentPasswordController.text,
            password: _passwordController.text,
            nonce: _nonceController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authPasswordChanged,
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint(
        'Change password failed: $error',
      );
      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).authChangePasswordFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  String? _validateNonce(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).authVerificationCodeRequired;
    }

    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).authCurrentPasswordRequired;
    }

    return null;
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
    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context).changePassword,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
              ),
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 52,
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      Text(
                        AppLocalizations.of(context).authReauthenticateTitle,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleLarge,
                      ),

                      const SizedBox(
                        height: AppSpacing.sm,
                      ),

                      Text(
                        AppLocalizations.of(context).authReauthenticateDescription,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(
                        height: AppSpacing.xl,
                      ),

                      if (!_codeSent)
                        PrimaryButton(
                          text: AppLocalizations.of(context).authSendCode,
                          isLoading: _isSendingCode,
                          onPressed: _sendReauthenticationCode,
                        )
                      else
                        _buildPasswordForm(),
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

  Widget _buildPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nonceController,
            label: AppLocalizations.of(context).authVerificationCode,
            hint: AppLocalizations.of(context).authVerificationCodeHint,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.oneTimeCode,
            ],
            validator: _validateNonce,
          ),

          const SizedBox(
            height: AppSpacing.sm,
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSendingCode
                  ? null
                  : _sendReauthenticationCode,
              child: Text(
                _isSendingCode
                    ? AppLocalizations.of(context).authSending
                    : AppLocalizations.of(context).authResendCode,
              ),
            ),
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          AppPasswordField(
            controller: _currentPasswordController,
            validator: _validateCurrentPassword,
            label: AppLocalizations.of(context).authCurrentPassword,
            hint: AppLocalizations.of(context).authCurrentPasswordHint,
          ),

          const SizedBox(
            height: AppSpacing.md,
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
            isLoading: _isChangingPassword,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}