import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/profile_controller_provider.dart';
import '../../../auth/application/kao_id_sso_handoff.dart';
import '../../../../../app/routes/kao_id_routes.dart';

final class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({
    super.key,
  });

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

final class _CompleteProfilePageState
    extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _languageCodeController;

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController();
    _languageCodeController = TextEditingController();

    Future.microtask(_loadProfile);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _languageCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    await ref
        .read(profileControllerProvider.notifier)
        .loadCurrentProfile();

    if (!mounted) {
      return;
    }

    final profile =
        ref.read(profileControllerProvider).profile;

    if (profile == null) {
      return;
    }

    _displayNameController.text =
        profile.displayName ?? '';

    _languageCodeController.text =
        profile.languageCode ?? 'th';
  }

  Future<void> _saveProfile() async {
    if (ref.read(profileControllerProvider).isLoading) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final state = ref.read(profileControllerProvider);
    final profile = state.profile;

    if (profile == null) {
      _showMessage(AppLocalizations.of(context).profileNotFound);
      return;
    }

    final updatedProfile = profile.copyWith(
      displayName: _displayNameController.text.trim(),
      languageCode: _languageCodeController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          profile: updatedProfile,
        );

    if (!mounted) {
      return;
    }

    final updatedState =
        ref.read(profileControllerProvider);

    if (updatedState.errorMessage != null) {
      _showMessage(AppLocalizations.of(context).profileSaveFailed);
      return;
    }

    _showMessage(
      AppLocalizations.of(context).profileSaved,
    );

    final consent = await KaoIdSsoHandoff.takePendingConsent();
    if (!mounted) return;
    if (consent != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        KaoIdRoutes.oauthConsent,
        (_) => false,
        arguments: consent,
      );
      return;
    }

    final returnedToService =
        await KaoIdSsoHandoff.tryReturnToService();
    if (!mounted || returnedToService) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      KaoIdRoutes.dashboard,
      (_) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).completeProfile),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 80,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      AppLocalizations.of(context).completeYourProfile,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      AppLocalizations.of(context).completeProfileDescription,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _displayNameController,
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          InputDecoration(
                        labelText: AppLocalizations.of(context).displayName,
                        hintText:
                            AppLocalizations.of(context).displayNameHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text =
                            value?.trim() ?? '';

                        if (text.isEmpty) {
                          return AppLocalizations.of(context).displayNameRequired;
                        }

                        if (text.length > 100) {
                          return AppLocalizations.of(context).displayNameTooLong;
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          _languageCodeController,
                      textInputAction:
                          TextInputAction.done,
                      decoration:
                          InputDecoration(
                        labelText:
                            AppLocalizations.of(context).preferredLanguage,
                        hintText:
                            AppLocalizations.of(context).languageCodeHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text =
                            value?.trim() ?? '';

                        if (text.isEmpty) {
                          return AppLocalizations.of(context).languageRequired;
                        }

                        return null;
                      },
                    ),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).profileLoadFailed,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .error,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    FilledButton(
                      onPressed:
                          state.isLoading
                              ? null
                              : _saveProfile,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context).saveProfile,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
