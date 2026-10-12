import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/profile_controller_provider.dart';
import '../../domain/entities/profile.dart';
import '../widgets/edit_profile/avatar_section.dart';

final class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  ConsumerState<EditProfilePage> createState() =>
      _EditProfilePageState();
}

final class _EditProfilePageState
    extends ConsumerState<EditProfilePage> {
  late final TextEditingController _displayNameController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController(
      text: widget.profile.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _clearPreview() {
    ref
        .read(profileControllerProvider.notifier)
        .clearSelectedAvatar();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentProfile =
        ref.read(profileControllerProvider).profile ??
            widget.profile;

    final displayName = _displayNameController.text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    final updatedProfile = currentProfile.copyWith(
      displayName: displayName,
    );

    await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          profile: updatedProfile,
        );

    if (!mounted) {
      return;
    }

    final updatedState = ref.read(profileControllerProvider);
    if (updatedState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).profileSaveFailed),
        ),
      );
      return;
    }

    _clearPreview();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).profileSaved,
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      profileControllerProvider,
    );

    return PopScope(
      onPopInvokedWithResult: (
        bool didPop,
        Object? result,
      ) {
        if (didPop) {
          _clearPreview();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).editProfile,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    AvatarSection(
                      avatarUrl:
                          state.profile?.avatarUrl ??
                              widget.profile.avatarUrl,
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Kao ID',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      AppLocalizations.of(context).kaoIdAvailableAfterVerification,
                    ),

                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _displayNameController,
                      textInputAction:
                          TextInputAction.done,
                      decoration:
                          InputDecoration(
                        labelText: AppLocalizations.of(context).displayName,
                        hintText:
                            AppLocalizations.of(context).displayNameExample,
                        helperText:
                            AppLocalizations.of(context).profileSharedDescription,
                        helperMaxLines: 6,
                        border:
                            const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final displayName = value
                                ?.trim()
                                .replaceAll(
                                  RegExp(r'\s+'),
                                  ' ',
                                ) ??
                            '';

                        if (displayName.length < 3) {
                          return AppLocalizations.of(context).displayNameMinLength;
                        }

                        if (displayName.length > 30) {
                          return AppLocalizations.of(context).displayNameMaxLength;
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: state.isLoading
                            ? null
                            : _updateProfile,
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
                                AppLocalizations.of(context).save,
                              ),
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
