import 'package:equatable/equatable.dart';

final class VerificationHistory extends Equatable {
  const VerificationHistory({
    required this.id,
    required this.verificationRequestId,
    required this.action,
    required this.oldStatus,
    required this.newStatus,
    required this.performedBy,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String verificationRequestId;
  final String action;
  final String? oldStatus;
  final String? newStatus;
  final String? performedBy;
  final String? notes;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        verificationRequestId,
        action,
        oldStatus,
        newStatus,
        performedBy,
        notes,
        createdAt,
      ];
}
