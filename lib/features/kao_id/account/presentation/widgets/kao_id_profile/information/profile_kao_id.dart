import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../issuance/application/providers/kao_id_issuance_provider.dart';

final class ProfileKaoId extends ConsumerWidget {
  const ProfileKaoId({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(currentKaoIdIdentityProvider);

    return identity.maybeWhen(
      data: (value) {
        if (value == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Kao ID : ${value.kaoId}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
