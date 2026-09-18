import 'package:equatable/equatable.dart';

final class VerificationRequest extends Equatable {
  const VerificationRequest({
    required this.id,
    required this.requestedBy,
    required this.status,
    required this.reviewedAt,
    required this.reviewedBy,
    required this.rejectionReason,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String requestedBy;
  final String status;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == 'pending';

  bool get isUnderReview =>
      status == 'under_review';

  bool get isApproved =>
      status == 'approved';

  bool get isRejected =>
      status == 'rejected';

  bool get isCancelled =>
      status == 'cancelled';

  bool get canSubmit =>
      isRejected || isCancelled;

  @override
  List<Object?> get props => [
        id,
        requestedBy,
        status,
        reviewedAt,
        reviewedBy,
        rejectionReason,
        notes,
        createdAt,
        updatedAt,
      ];
}