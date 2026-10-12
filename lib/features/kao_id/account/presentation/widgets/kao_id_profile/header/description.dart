import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

final class ProfileDescription extends StatelessWidget {
  const ProfileDescription({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).profileDescription,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
