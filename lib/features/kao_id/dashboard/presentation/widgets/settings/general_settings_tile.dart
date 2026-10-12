import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaosure/core/localization/locale_controller.dart';
import 'package:kaosure/core/localization/app_languages.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../security/dashboard_menu_tile.dart';

final class GeneralSettingsTile extends ConsumerStatefulWidget {
  const GeneralSettingsTile({super.key});

  @override
  ConsumerState<GeneralSettingsTile> createState() =>
      _GeneralSettingsTileState();
}

class _GeneralSettingsTileState
    extends ConsumerState<GeneralSettingsTile> {
  bool _busy = false;

  Future<void> _chooseLanguage() async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);

    try {
      final l10n = AppLocalizations.of(context);
      final currentTag =
          ref.read(localeControllerProvider)?.toLanguageTag() ??
              'system';

      final options = <String, String>{
        'system': l10n.languageSystem,
        ...appLanguageNames,
      };

      final selectedTag = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return SimpleDialog(
            title: Text(l10n.language),
            children: [
              for (final option in options.entries)
                ListTile(
                  title: Text(option.value),
                  selected: currentTag == option.key,
                  trailing: currentTag == option.key
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    Navigator.of(dialogContext).pop(option.key);
                  },
                ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(l10n.cancel),
              ),
            ],
          );
        },
      );

      if (!mounted ||
          selectedTag == null ||
          selectedTag == currentTag) {
        return;
      }

      final locale = selectedTag == 'system'
          ? null
          : findSupportedLocale(selectedTag);

      if (selectedTag != 'system' && locale == null) {
        throw StateError('Unsupported locale: $selectedTag');
      }

      await ref
          .read(localeControllerProvider.notifier)
          .setLocale(locale);
    } catch (error, stackTrace) {
      debugPrint('Language selection failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).languageSaveFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);

    final languageName = appLanguageName(locale, l10n.languageSystem);

    return AbsorbPointer(
      absorbing: _busy,
      child: Opacity(
        opacity: _busy ? 0.6 : 1,
        child: DashboardMenuTile(
          icon: Icons.language_outlined,
          title: l10n.language,
          subtitle: languageName,
          onTap: _chooseLanguage,
        ),
      ),
    );
  }
}