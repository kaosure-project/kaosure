import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../domain/entities/business_registration.dart';
import '../../../../domain/entities/business_type.dart';
import '../../../utils/business_registration_texts.dart';
import '../../common/step_actions.dart';
import '../../common/step_header.dart';
import 'business_type_selector.dart';

typedef SaveBusinessDetails = Future<void> Function({
  required String businessType,
  required String businessName,
  required String registrationNumber,
  required String businessCategory,
  String? businessDescription,
});

class BusinessDetailsStep extends StatefulWidget {
  const BusinessDetailsStep({
    super.key,
    required this.initial,
    required this.busy,
    required this.onSave,
  });

  final BusinessRegistration? initial;
  final bool busy;
  final SaveBusinessDetails onSave;

  @override
  State<BusinessDetailsStep> createState() => _BusinessDetailsStepState();
}

class _BusinessDetailsStepState extends State<BusinessDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.businessName);
  late final _number = TextEditingController(text: widget.initial?.registrationNumber);
  late final _description =
      TextEditingController(text: widget.initial?.businessDescription);
  late String _type = BusinessType.values.contains(widget.initial?.businessType)
      ? widget.initial!.businessType
      : BusinessType.registeredBusiness;
  late String? _category = BusinessCategory.values.contains(widget.initial?.businessCategory)
      ? widget.initial!.businessCategory
      : null;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      businessType: _type,
      businessName: _name.text,
      registrationNumber: _number.text,
      businessCategory: _category!,
      businessDescription: _description.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final company = _type == BusinessType.registeredBusiness;
    String? required(String? value) =>
        (value == null || value.trim().isEmpty) ? l10n.businessRegFieldRequired : null;
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepHeader(title: l10n.businessRegDetailsHeading,
              description: l10n.businessRegDetailsDescription),
          BusinessTypeSelector(
            value: _type,
            onChanged: widget.busy ? null : (type) => setState(() => _type = type),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _name,
            enabled: !widget.busy,
            maxLength: 200,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.businessRegNameLabel, counterText: ''),
            validator: required,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _number,
            enabled: !widget.busy,
            keyboardType: company ? TextInputType.number : TextInputType.text,
            inputFormatters: company
                ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)]
                : [LengthLimitingTextInputFormatter(30)],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.businessRegNumberLabel,
              helperText: company ? l10n.businessRegNumberHelp : null,
            ),
            validator: (value) => required(value) ??
                (company && !RegExp(r'^\d{13}$').hasMatch(value!.trim())
                    ? l10n.businessRegNumberInvalid
                    : null),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(labelText: l10n.businessRegCategoryLabel),
            items: [
              for (final category in BusinessCategory.values)
                DropdownMenuItem(value: category, child: Text(l10n.businessCategoryLabel(category))),
            ],
            onChanged: widget.busy ? null : (value) => setState(() => _category = value),
            validator: required,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            enabled: !widget.busy,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(labelText: l10n.businessRegDescriptionLabel),
          ),
          StepActions(
            primaryLabel: l10n.businessRegContinue,
            onPrimary: _save,
            busy: widget.busy,
          ),
        ],
      ),
    );
  }
}
