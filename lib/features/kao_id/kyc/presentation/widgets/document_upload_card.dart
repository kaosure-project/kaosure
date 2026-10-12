import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/widgets/cards/app_card.dart';

import 'document_info_card.dart';
import 'info_tile.dart';
import 'status_chip.dart';
import 'upload_area.dart';

final class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.expiryText,
    required this.frontButtonText,
    required this.onUploadFront,
    required this.backButtonText,
    required this.onUploadBack,
    this.frontFileName,
    this.frontFileSize,
    this.onChangeFrontFile,
    this.backFileName,
    this.backFileSize,
    this.onChangeBackFile,
  });

  final IconData icon;
  final String title;
  final String description;

  final String status;
  final Color statusColor;
  final IconData statusIcon;

  final String expiryText;

  final String frontButtonText;
  final VoidCallback onUploadFront;

  final String backButtonText;
  final VoidCallback onUploadBack;

  final String? frontFileName;
  final String? frontFileSize;
  final VoidCallback? onChangeFrontFile;

  final String? backFileName;
  final String? backFileSize;
  final VoidCallback? onChangeBackFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  _DocumentHeader(
                    icon: icon,
                    title: title,
                    description: description,
                    status: status,
                    statusColor: statusColor,
                    statusIcon: statusIcon,
                  ),

                  _DocumentInformation(
                    expiryText: expiryText,
                  ),

                  const Divider(height: 1),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      28,
                      28,
                      28,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _DocumentSideSection(
                          title: AppLocalizations.of(context).kycFrontOfCard,
                          fileName: frontFileName,
                          fileSize: frontFileSize,
                          onChange: onChangeFrontFile,
                          buttonText: frontButtonText,
                          onUpload: onUploadFront,
                        ),

                        const SizedBox(height: 32),

                        Divider(
                          color:
                              colorScheme.outlineVariant,
                        ),

                        const SizedBox(height: 32),

                        _DocumentSideSection(
                          title: AppLocalizations.of(context).kycBackOfCard,
                          fileName: backFileName,
                          fileSize: backFileSize,
                          onChange: onChangeBackFile,
                          buttonText: backButtonText,
                          onUpload: onUploadBack,
                        ),

                        const SizedBox(height: 32),

                        _UploadRequirements(),
                      ],
                    ),
                  ),
                ],
              ),
            );
  }
}

final class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
  });

  final IconData icon;
  final String title;
  final String description;
  final String status;
  final Color statusColor;
  final IconData statusIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        28,
        32,
        28,
        28,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.28),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: statusColor.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: Icon(
              icon,
              size: 38,
              color: statusColor,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 10),

          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                color:
                    colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 18),

          StatusChip(
            status: status,
          ),
        ],
      ),
    );
  }
}

final class _DocumentInformation
    extends StatelessWidget {
  const _DocumentInformation({
    required this.expiryText,
  });

  final String expiryText;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        28,
        20,
        28,
        24,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant,
          ),
        ),
        child: InfoTile(
          icon: Icons.event_outlined,
          title: AppLocalizations.of(context).kycExpiryDate,
          value: expiryText,
        ),
      ),
    );
  }
}

final class _DocumentSideSection
    extends StatelessWidget {
  const _DocumentSideSection({
    required this.title,
    required this.fileName,
    required this.fileSize,
    required this.onChange,
    required this.buttonText,
    required this.onUpload,
  });

  final String title;
  final String? fileName;
  final String? fileSize;
  final VoidCallback? onChange;
  final String buttonText;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasFile = fileName != null;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hasFile)
              _UploadedBadge(),
          ],
        ),

        const SizedBox(height: 14),

        if (hasFile) ...[
          DocumentInfoCard(
            fileName: fileName!,
            fileSize: fileSize ?? '—',
            uploadDate: AppLocalizations.of(context).kycToday,
            onChange: onChange,
          ),
          const SizedBox(height: 14),
        ],

        UploadArea(
          onPressed: onUpload,
        ),

        const SizedBox(height: 8),

        Text(
          hasFile
              ? AppLocalizations.of(context).kycYouCanChooseAnotherFileTo
              : buttonText,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(
            color:
                colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

final class _UploadedBadge
    extends StatelessWidget {
  const _UploadedBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius:
            BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 15,
            color:
                colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 5),
          Text(
            AppLocalizations.of(context).kycSelected,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme
                      .onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

final class _UploadRequirements
    extends StatelessWidget {
  const _UploadRequirements();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer
            .withValues(alpha: 0.32),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary
              .withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      colorScheme.primary,
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 20,
                  color:
                      colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).kycUploadRequirements,
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(context).kycCheckTheInformationBeforeSubmitting,
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

           _RequirementItem(
            icon: Icons.credit_card_outlined,
            text:
                AppLocalizations.of(context).kycChooseImagesOfBothSidesOf,
          ),

          const SizedBox(height: 12),

           _RequirementItem(
            icon: Icons.image_outlined,
            text:
                AppLocalizations.of(context).kycJpgAndPngSupported,
          ),

          const SizedBox(height: 12),

           _RequirementItem(
            icon: Icons.data_usage_outlined,
            text:
                AppLocalizations.of(context).kycCheckThatTheImageIsClear,
          ),

          const SizedBox(height: 12),

           _RequirementItem(
            icon: Icons.lock_outline,
            text:
                AppLocalizations.of(context).kycSelectingAFileDoesNotUpload,
          ),
        ],
      ),
    );
  }
}

final class _RequirementItem
    extends StatelessWidget {
  const _RequirementItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall
                ?.copyWith(
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}