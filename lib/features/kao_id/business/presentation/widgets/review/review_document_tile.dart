import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class ReviewDocumentTile extends StatelessWidget {
  const ReviewDocumentTile({
    super.key,
    required this.name,
    required this.isPdf,
    required this.viewed,
    required this.onOpen,
  });

  final String name;
  final bool isPdf;
  final bool viewed;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined),
      title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: viewed
          ? Row(children: [
              Icon(Icons.check_circle, size: 16, color: scheme.primary),
              const SizedBox(width: 4),
              Text(l10n.businessReviewDocumentViewed),
            ])
          : null,
      trailing: OutlinedButton(
        onPressed: onOpen,
        child: Text(l10n.businessReviewOpenDocument),
      ),
    );
  }
}
