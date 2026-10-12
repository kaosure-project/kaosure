import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/profile_controller_provider.dart';
import '../../application/states/profile_state.dart';
import '../widgets/kao_id_profile/card.dart';

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

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(
              profileControllerProvider.notifier,
            )
            .loadCurrentProfile();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          if (widget.embedded) ...[
            Text(AppLocalizations.of(context).accountTitle,
              style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
          ],
          KaoIdProfileCard(
            profile: state.profile!,
          ),

        ],
      ),
    );
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
