import '../../domain/entities/business_organization.dart';

/// Row shape of `kaoid_private.my_organizations_r27c`.
abstract final class BusinessOrganizationModel {
  static BusinessOrganization fromJson(Map<String, dynamic> json) {
    String? text(Map<String, dynamic> source, String key) {
      final value = source[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final shop = json['shop'];
    return BusinessOrganization(
      organizationId: json['organization_id'].toString(),
      name: text(json, 'name') ?? '',
      role: text(json, 'role') ?? '',
      legalName: text(json, 'legal_name'),
      legalNameEn: text(json, 'legal_name_en'),
      registrationNumber: text(json, 'registration_number'),
      verificationStatus: text(json, 'verification_status'),
      businessKaoId: text(json, 'business_kao_id'),
      kaoIdStatus: text(json, 'kao_id_status'),
      canManageBank: json['can_manage_bank'] == true,
      bankVerified: json['bank_verified'] == true,
      banks: [
        for (final bank in json['banks'] as List? ?? const [])
          if (bank is Map) _bank(Map<String, dynamic>.from(bank), text),
      ],
      shopName: shop is Map ? shop['name']?.toString() : null,
    );
  }

  static OrganizationBank _bank(Map<String, dynamic> json, String? Function(Map<String, dynamic>, String) text) {
    return OrganizationBank(
      id: json['id'].toString(),
      bankName: text(json, 'bank_name') ?? '',
      accountName: text(json, 'account_name') ?? '',
      last4: text(json, 'last4') ?? '',
      status: switch (json['status']) {
        'verified' || 'approved' => OrganizationBankStatus.approved,
        'rejected' || 'expired' => OrganizationBankStatus.rejected,
        _ => OrganizationBankStatus.pending,
      },
      reason: text(json, 'reason'),
      submittedAt: DateTime.tryParse(text(json, 'submitted_at') ?? '')?.toLocal(),
      verifiedAt: DateTime.tryParse(text(json, 'verified_at') ?? '')?.toLocal(),
    );
  }
}
