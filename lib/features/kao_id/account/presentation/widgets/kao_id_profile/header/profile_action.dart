import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../domain/entities/profile.dart';
import 'package:kaosure/features/kao_id/router/kao_id_routes.dart';

final class ProfileAction extends StatelessWidget {
  const ProfileAction({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushNamed(
            KaoIdRoutes.editProfile,
            arguments: profile,
          );
        },
        child: Text(AppLocalizations.of(context).editProfile),
      ),
    );
  }
}
