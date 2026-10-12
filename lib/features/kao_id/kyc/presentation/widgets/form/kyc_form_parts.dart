import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../../domain/entities/id_image.dart';

/// Titled white panel grouping one part of a KYC form.
class KycFormPanel extends StatelessWidget {
  const KycFormPanel({super.key, required this.title, required this.icon, required this.children,
    this.subtitle, this.color = AppColors.kaoBlue});

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final hint = subtitle;
    return DashboardPanel(
      title: title,
      icon: icon,
      iconColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (hint != null) ...[
          Text(hint, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
        ],
        ...children,
      ]),
    );
  }
}

/// Date shown like a text field; tapping opens the date picker.
class KycDateField extends StatelessWidget {
  const KycDateField({super.key, required this.fieldKey, required this.label, required this.value,
    required this.onTap, this.errorText});

  final String fieldKey;
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        key: ValueKey(fieldKey),
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            errorMaxLines: 3,
            enabled: onTap != null,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(date == null ? l10n.kycSelectDate
              : MaterialLocalizations.of(context).formatMediumDate(date),
            style: TextStyle(color: date == null ? AppColors.textSecondary : AppColors.textPrimary)),
        ),
      ),
    );
  }
}

/// Picked document image with a choose button.
class KycImagePicker extends StatelessWidget {
  const KycImagePicker({super.key, required this.buttonKey, required this.title, required this.image,
    required this.onPick, this.errorText});

  final String buttonKey;
  final String title;
  final IdImage? image;
  final VoidCallback? onPick;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final picked = image;
    final error = errorText;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: error == null ? AppColors.divider : AppColors.error),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (picked != null) ...[
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: Image.memory(picked.bytes, height: 150, fit: BoxFit.contain)),
          const SizedBox(height: 4),
          Text(picked.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: ValueKey(buttonKey),
          onPressed: onPick,
          icon: const Icon(Icons.image_outlined),
          label: Text(l10n.kycChooseFile),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error, style: const TextStyle(color: AppColors.error)),
        ],
      ]),
    );
  }
}

/// Inline error under the submit button, announced to screen readers.
class KycFormMessage extends StatelessWidget {
  const KycFormMessage({super.key, required this.message, this.error = true});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: error ? AppColors.kaoDangerSoft : AppColors.kaoBlueSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(error ? Icons.error_outline : Icons.info_outline,
              color: error ? AppColors.error : AppColors.kaoBlue, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ]),
        ),
      );
}
