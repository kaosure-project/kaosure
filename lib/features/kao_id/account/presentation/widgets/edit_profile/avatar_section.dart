import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/providers/core_providers.dart';
import '../../../../../../core/services/image_picker_service.dart';
import '../../../application/providers/profile_controller_provider.dart';

final class AvatarSection extends ConsumerWidget {
  const AvatarSection({super.key, required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);

    ImageProvider? imageProvider;

    if (state.selectedAvatarBytes != null) {
      imageProvider = MemoryImage(state.selectedAvatarBytes!);
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(avatarUrl!);
    }

    return Center(
      child: SizedBox(
        width: 120,
        height: 180,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageProvider == null
                      ? const Icon(Icons.person, size: 48)
                      : Image(
                          image: imageProvider,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Avatar Error : $error');

                            return const Icon(Icons.person, size: 48);
                          },
                        ),
                ),

                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () async {
                        final picker = ref.read(imagePickerServiceProvider);

                        final image = await picker.pickImage(
                          type: ImageType.logo,
                        );

                        if (image == null) {
                          return;
                        }

                        ref
                            .read(profileControllerProvider.notifier)
                            .selectAvatar(image: image);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (state.selectedAvatarName != null)
              Text(
                state.selectedAvatarName!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

            if (state.selectedAvatarSize != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${(state.selectedAvatarSize! / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

