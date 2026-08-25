import 'package:flutter/material.dart';

import '../../../account/domain/entities/profile.dart';
import '../../../dashboard/presentation/widgets/profile/profile_avatar.dart';
import '../../../dashboard/presentation/widgets/profile/profile_completion.dart';
import '../../../dashboard/presentation/widgets/profile/profile_information.dart';

final class IdentityHeader extends StatelessWidget {
  const IdentityHeader({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final isCompact =
                    constraints.maxWidth < 600;

                if (isCompact) {
                  return _CompactProfileHeader(
                    profile: profile,
                  );
                }

                return _WideProfileHeader(
                  profile: profile,
                );
              },
            ),

            const SizedBox(height: 24),

            Divider(
              height: 1,
              color: colorScheme.outlineVariant,
            ),

            const SizedBox(height: 20),

            _CompletionSection(
              profile: profile,
            ),
          ],
        ),
      ),
    );
  }
}

final class _WideProfileHeader
    extends StatelessWidget {
  const _WideProfileHeader({
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileAvatar(
          profile: profile,
        ),

        const SizedBox(width: 16),

        ProfileInformation(
          profile: profile,
        ),
      ],
    );
  }
}

final class _CompactProfileHeader
    extends StatelessWidget {
  const _CompactProfileHeader({
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProfileAvatar(
          profile: profile,
        ),

        const SizedBox(height: 16),

        ProfileInformation(
          profile: profile,
        ),
      ],
    );
  }
}

final class _CompletionSection
    extends StatelessWidget {
  const _CompletionSection({
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'ความสมบูรณ์ของบัญชี',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'บัญชีของคุณ',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ProfileCompletion(
          profile: profile,
        ),
      ],
    );
  }
}