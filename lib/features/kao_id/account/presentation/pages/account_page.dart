import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/routes/kao_id_routes.dart';
import '../../../issuance/application/providers/kao_id_issuance_provider.dart';
import '../../application/providers/profile_controller_provider.dart';
import '../../application/states/profile_state.dart';
import '../../domain/entities/profile.dart';
import '../widgets/account_overview.dart';

final class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<AccountPage> createState() =>
      _AccountPageState();
}

final class _AccountPageState
    extends ConsumerState<AccountPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(profileControllerProvider.notifier)
          .loadCurrentProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      profileControllerProvider,
    );

    if (widget.embedded) return _buildBody(context, state);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).accountTitle),
      ),
      body: SafeArea(
        child: _buildBody(
          context,
          state,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProfileState state,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.errorMessage != null) {
      return _ErrorView(
        message: AppLocalizations.of(context).profileLoadFailed,
        onRetry: () {
          ref
              .read(
                profileControllerProvider.notifier,
              )
              .loadCurrentProfile();
        },
      );
    }

    if (state.profile == null) {
      return const _EmptyProfileView();
    }

    final profile = state.profile!;
    return AccountOverview(
      profile: profile,
      onEdit: () => _editProfile(profile),
      onRefresh: () async {
        ref.invalidate(currentKaoIdIdentityProvider);
        await ref.read(profileControllerProvider.notifier).loadCurrentProfile();
      },
    );
  }

  Future<void> _editProfile(Profile profile) async {
    await Navigator.of(context).pushNamed(KaoIdRoutes.editProfile, arguments: profile);
    if (mounted) await ref.read(profileControllerProvider.notifier).loadCurrentProfile();
  }
}

final class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

final class _EmptyProfileView extends StatelessWidget {
  const _EmptyProfileView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppLocalizations.of(context).profileNotFound,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
