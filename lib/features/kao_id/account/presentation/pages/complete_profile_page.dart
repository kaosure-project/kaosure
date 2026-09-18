import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/profile_controller_provider.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final state = ref.read(profileControllerProvider);
    final profile = state.profile;

    if (profile == null) {
      _showMessage('ไม่พบข้อมูล Profile');
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
      _showMessage(updatedState.errorMessage!);
      return;
    }

    _showMessage(
      'บันทึกข้อมูล Profile สำเร็จ',
    );

    // ขั้นถัดไปเราจะเชื่อม Router ไป KYC
    // ยังไม่ navigate ตอนนี้จนกว่า flow KYC จะถูกตรวจครบ
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
        title: const Text('Complete Profile'),
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

                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Set up your basic Kao ID profile.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _displayNameController,
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          const InputDecoration(
                        labelText: 'Display Name',
                        hintText:
                            'Name shown to other users',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text =
                            value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'กรุณากรอก Display Name';
                        }

                        if (text.length > 100) {
                          return 'Display Name ยาวเกินไป';
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
                          const InputDecoration(
                        labelText:
                            'Preferred Language',
                        hintText:
                            'เช่น th หรือ en',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text =
                            value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'กรุณาระบุภาษา';
                        }

                        return null;
                      },
                    ),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage!,
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
                          : const Text(
                              'Save Profile',
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