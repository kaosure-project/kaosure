import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

class PickerOption<T> {
  const PickerOption({required this.value, required this.label, this.detail, this.terms = ''});

  final T value;
  final String label;
  final String? detail;

  /// Extra text matched by search (codes, names in other languages).
  final String terms;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || '$label ${detail ?? ''} $terms'.toLowerCase().contains(q);
  }
}

/// Read-only field that opens a searchable list. Tap targets are keyed
/// `fieldKey`, `fieldKey-search` and `fieldKey-option-<value>`.
class SearchablePickerField<T> extends StatelessWidget {
  const SearchablePickerField({super.key, required this.fieldKey, required this.label,
    required this.options, required this.value, required this.onChanged,
    this.enabled = true, this.errorText, this.helperText, this.icon});

  final String fieldKey;
  final String label;
  final List<PickerOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final String? errorText;
  final String? helperText;
  final IconData? icon;

  PickerOption<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final chosen = await showDialog<T>(
      context: context,
      builder: (_) => _PickerDialog<T>(fieldKey: fieldKey, title: label, options: options, selected: value),
    );
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final text = Theme.of(context).textTheme;
    return InkWell(
      key: ValueKey(fieldKey),
      onTap: enabled ? () => _open(context) : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: selected == null,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          errorText: errorText,
          errorMaxLines: 2,
          enabled: enabled,
          border: const OutlineInputBorder(),
          prefixIcon: icon == null ? null : Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: selected == null
            ? null
            : Text(selected.detail == null ? selected.label : '${selected.label} · ${selected.detail}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
      ),
    );
  }
}

class _PickerDialog<T> extends StatefulWidget {
  const _PickerDialog({required this.fieldKey, required this.title, required this.options,
    required this.selected});

  final String fieldKey;
  final String title;
  final List<PickerOption<T>> options;
  final T? selected;

  @override
  State<_PickerDialog<T>> createState() => _PickerDialogState<T>();
}

class _PickerDialogState<T> extends State<_PickerDialog<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = [for (final option in widget.options) if (option.matches(_query)) option];
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(children: [
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700))),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              key: ValueKey('${widget.fieldKey}-search'),
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.pickerSearch,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Flexible(
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.pickerNoResults, textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final option = shown[index];
                      final selected = option.value == widget.selected;
                      return ListTile(
                        key: ValueKey('${widget.fieldKey}-option-${option.value}'),
                        title: Text(option.label),
                        subtitle: option.detail == null ? null : Text(option.detail!),
                        selected: selected,
                        trailing: selected ? const Icon(Icons.check, color: AppColors.kaoBlue) : null,
                        onTap: () => Navigator.of(context).pop(option.value),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
