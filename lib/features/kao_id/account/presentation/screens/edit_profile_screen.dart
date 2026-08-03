import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/profile.dart';
import '../providers/profile_controller_provider.dart';
import '../widgets/edit_profile/avatar_section.dart';

final class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

final class _EditProfileScreenState
    extends ConsumerState<EditProfileScreen> {
  late final TextEditingController
      _displayNameController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _displayNameController =
        TextEditingController(
      text: widget.profile.displayName ?? '',
    );
  }

  @override
void dispose() {
  _displayNameController.dispose();

  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      profileControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 500,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding:
                  const EdgeInsets.all(24),
              children: [
                AvatarSection(
                  avatarUrl:
                      state.profile
                          ?.avatarUrl ??
                      widget.profile
                          .avatarUrl,
                ),

                const SizedBox(
                  height: 32,
                ),

                const Text(
                  'Kao ID',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'จะสามารถใช้งานได้หลังจากยืนยันตัวตน',
                ),

                const SizedBox(
                  height: 32,
                ),

                TextFormField(
                  controller:
                      _displayNameController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Display Name',
                    hintText:
                        'เช่น เก๋าชัวร์ Official',
                    helperText:
                        'ชื่อที่แสดงนี้จะใช้ในทุกบริการของ Kao ID และสามารถเปลี่ยนได้ภายหลัง',
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final displayName =
                        value
                                ?.trim()
                                .replaceAll(
                                  RegExp(
                                    r'\s+',
                                  ),
                                  ' ',
                                ) ??
                            '';

                    if (displayName
                            .length <
                        3) {
                      return 'ชื่อที่แสดงต้องมีอย่างน้อย 3 ตัวอักษร';
                    }

                    if (displayName
                            .length >
                        30) {
                      return 'ชื่อที่แสดงต้องไม่เกิน 30 ตัวอักษร';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Icon(
                      Icons
                          .info_outline,
                      size: 18,
                      color: Colors
                          .black87,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'รูปโปรไฟล์จะถูกอัปโหลดเมื่อกด "บันทึก"',
                        style:
                            TextStyle(
                          fontSize:
                              13,
                          color: Colors
                              .black87,
                          height:
                              1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 32,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      FilledButton(
                    onPressed:
                        state.isLoading
                            ? null
                            : () async {
                                if (!_formKey
                                    .currentState!
                                    .validate()) {
                                  return;
                                }

                                final updatedProfile =
                                    widget
                                        .profile
                                        .copyWith(
                                  displayName:
                                      _displayNameController
                                          .text
                                          .trim()
                                          .replaceAll(
                                            RegExp(
                                              r'\s+',
                                            ),
                                            ' ',
                                          ),
                                );

                                await ref
                                    .read(
                                      profileControllerProvider
                                          .notifier,
                                    )
                                    .updateProfile(
                                      profile:
                                          updatedProfile,
                                    );

                                if (!context
                                    .mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(
                                        context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text(
                                      'Profile updated successfully',
                                    ),
                                  ),
                                );

                                Navigator.pop(
                                  context,
                                );
                              },
                    child: state
                            .isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
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
    );
  }
}