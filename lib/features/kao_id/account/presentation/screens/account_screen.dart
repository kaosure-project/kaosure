import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_controller_provider.dart';
import '../widgets/kao_id_profile/card.dart';

final class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({
    super.key,
  });

  @override
  ConsumerState<AccountScreen> createState() =>
      _AccountScreenState();
}

final class _AccountScreenState
    extends ConsumerState<AccountScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
        ),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: Text(
                state.errorMessage!,
              ),
            );
          }

          if (state.profile == null) {
            return const Center(
              child: Text(
                'Profile not found',
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                KaoIdProfileCard(
                  profile: state.profile!,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}