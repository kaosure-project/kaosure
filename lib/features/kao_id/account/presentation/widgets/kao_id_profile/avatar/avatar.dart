import 'package:flutter/material.dart';

import '../../../../domain/entities/profile.dart';

final class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    const imageUrl =
        'https://dyfpzmhalfmykvxjdcoq.supabase.co/storage/v1/object/public/avatars/9044e32e-24e7-49e2-9aaf-500c48ecce7e/avatar_1785492659817.jpg';

    return ClipOval(
      child: Image.network(
        imageUrl,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          if (loadingProgress == null) {
            debugPrint('IMAGE LOADED SUCCESS');
            return child;
          }

          return const SizedBox(
            width: 84,
            height: 84,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          debugPrint('========== IMAGE ERROR ==========');
          debugPrint(error.toString());
          debugPrint(stackTrace.toString());
          debugPrint('=================================');

          return const CircleAvatar(
            radius: 42,
            child: Icon(
              Icons.error,
              size: 42,
            ),
          );
        },
      ),
    );
  }
}