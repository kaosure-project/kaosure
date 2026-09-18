import 'package:flutter/material.dart';
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

    _clearPreview();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'บันทึกข้อมูลโปรไฟล์เรียบร้อยแล้ว',
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
          title: const Text(
            'แก้ไขโปรไฟล์',
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

                    const Text(
                      'จะสามารถใช้งานได้หลังจากยืนยันตัวตน',
                    ),

                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _displayNameController,
                      textInputAction:
                          TextInputAction.done,
                      decoration:
                          const InputDecoration(
                        labelText: 'ชื่อ',
                        hintText:
                            'เช่น เก๋าชัวร์ Official',
                        helperText:
                            'ชื่อและรูปที่แสดงนี้จะใช้ในทุกบริการของ Kao ID และสามารถเปลี่ยนได้ภายหลัง',
                        border:
                            OutlineInputBorder(),
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
                          return 'ชื่อต้องมีอย่างน้อย 3 ตัวอักษร';
                        }

                        if (displayName.length > 30) {
                          return 'ชื่อต้องไม่เกิน 30 ตัวอักษร';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'รูปโปรไฟล์และชื่อจะแสดงในบริการต่าง ๆ ของ Kao ID',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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
                            : const Text(
                                'บันทึก',
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