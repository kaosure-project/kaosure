import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaosure/l10n/app_localizations.dart';

String realValue(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? '—' : text;
}
String adminDate(BuildContext context, dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) { return '—'; }
  final d = parsed.toLocal();
  final m = MaterialLocalizations.of(context);
  final offset = d.timeZoneOffset.inMinutes;
  final zone = '${offset < 0 ? '-' : '+'}${(offset.abs() ~/ 60).toString().padLeft(2, '0')}:${(offset.abs() % 60).toString().padLeft(2, '0')}';
  return '${m.formatFullDate(d)} · ${m.formatTimeOfDay(TimeOfDay.fromDateTime(d), alwaysUse24HourFormat: true)} (UTC$zone)';
}
class AdminValue extends StatelessWidget {
  const AdminValue({super.key, required this.label, required this.value, this.copyable = false});
  final String label;
  final dynamic value;
  final bool copyable;
  @override
  Widget build(BuildContext context) {
    final text = realValue(value);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4), SelectableText(text),
        ])), if (copyable && text != '—') IconButton(
          tooltip: AppLocalizations.of(context).adminCopy,
          onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          icon: const Icon(Icons.copy_outlined, size: 18)),
      ]));
  }
}
class AdminSection extends StatelessWidget {
  const AdminSection({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12), ...children,
      ])));
}

String adminRoles(AppLocalizations l, dynamic roles) {
  if (roles is! List || roles.isEmpty) { return '—'; }
  return roles.map((r) => switch(r) {
    'owner' => l.adminOwner, 'admin' => l.staffAdmin,
    'super_admin' => l.staffSuperAdmin, 'support' => l.staffSupport,
    'kyc_officer' => l.staffReviewer, _ => l.kycUnknownStatus,
  }).join(', ');
}
