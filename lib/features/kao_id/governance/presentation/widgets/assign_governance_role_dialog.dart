import 'package:flutter/material.dart';

import '../../domain/entities/governance_role.dart';

final class AssignGovernanceRoleDialog
    extends StatefulWidget {
  const AssignGovernanceRoleDialog({
    super.key,
    required this.roles,
    required this.onSubmit,
  });

  final List<GovernanceRole> roles;
  final Future<bool> Function({
    required String kaoId,
    required String roleCode,
  }) onSubmit;

  @override
  State<AssignGovernanceRoleDialog> createState() =>
      _AssignGovernanceRoleDialogState();
}

final class _AssignGovernanceRoleDialogState
    extends State<AssignGovernanceRoleDialog> {
  final _kaoIdController =
      TextEditingController();
  String? _roleCode;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _kaoIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final kaoId =
        _kaoIdController.text.trim();

    if (kaoId.isEmpty ||
        _roleCode == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await widget.onSubmit(
      kaoId: kaoId,
      roleCode: _roleCode!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          const Text('แต่งตั้งผู้ดูแลระบบ'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _kaoIdController,
              textCapitalization:
                  TextCapitalization.characters,
              decoration:
                  const InputDecoration(
                labelText: 'Kao ID',
                hintText: 'KXXXXXXXXXX',
                prefixIcon: Icon(
                  Icons.badge_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _roleCode,
              decoration:
                  const InputDecoration(
                labelText: 'บทบาท',
                prefixIcon: Icon(
                  Icons
                      .admin_panel_settings_outlined,
                ),
              ),
              items: widget.roles
                  .map(
                    (role) =>
                        DropdownMenuItem(
                      value: role.code,
                      child:
                          Text(role.name),
                    ),
                  )
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _roleCode = value;
                      });
                    },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () =>
                  Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed:
              _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('แต่งตั้ง'),
        ),
      ],
    );
  }
}
