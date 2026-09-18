import '../../domain/entities/governance_access.dart';
import '../../domain/entities/governance_assignment.dart';
import '../../domain/entities/governance_role.dart';

final class GovernanceState {
  const GovernanceState({
    required this.isLoading,
    required this.isSubmitting,
    required this.access,
    required this.roles,
    required this.assignments,
    required this.errorMessage,
  });

  factory GovernanceState.initial() {
    return const GovernanceState(
      isLoading: false,
      isSubmitting: false,
      access: null,
      roles: [],
      assignments: [],
      errorMessage: null,
    );
  }

  final bool isLoading;
  final bool isSubmitting;
  final GovernanceAccess? access;
  final List<GovernanceRole> roles;
  final List<GovernanceAssignment> assignments;
  final String? errorMessage;

  bool get canAccess =>
      access?.canAccessAdmin ?? false;
}
