import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/governance_assignment.dart';
import '../../domain/entities/governance_role.dart';
import '../../domain/repositories/governance_repository.dart';
import '../states/governance_state.dart';

final class GovernanceController
    extends StateNotifier<GovernanceState> {
  GovernanceController(
    this._repository,
  ) : super(GovernanceState.initial());

  final GovernanceRepository _repository;

  Future<void> load() async {
    state = GovernanceState(
      isLoading: true,
      isSubmitting: false,
      access: state.access,
      roles: state.roles,
      assignments: state.assignments,
      errorMessage: null,
    );

    try {
      final access = await _repository.getAccess();

      if (!access.canAccessAdmin) {
        state = GovernanceState(
          isLoading: false,
          isSubmitting: false,
          access: access,
          roles: const [],
          assignments: const [],
          errorMessage: null,
        );
        return;
      }

      final List<GovernanceRole> roles =
          access.canAssignAdmin
              ? await _repository.getRoles()
              : const [];

      final List<GovernanceAssignment> assignments =
          access.canViewAssignments
              ? await _repository.getAssignments()
              : const [];

      state = GovernanceState(
        isLoading: false,
        isSubmitting: false,
        access: access,
        roles: roles,
        assignments: assignments,
        errorMessage: null,
      );
    } catch (error) {
      state = GovernanceState(
        isLoading: false,
        isSubmitting: false,
        access: state.access,
        roles: state.roles,
        assignments: state.assignments,
        errorMessage: error.toString(),
      );
    }
  }

  Future<bool> assignRole({
    required String kaoId,
    required String roleCode,
  }) async {
    state = GovernanceState(
      isLoading: state.isLoading,
      isSubmitting: true,
      access: state.access,
      roles: state.roles,
      assignments: state.assignments,
      errorMessage: null,
    );

    try {
      await _repository.assignRole(
        kaoId: kaoId,
        roleCode: roleCode,
      );
      await load();
      return true;
    } catch (error) {
      state = GovernanceState(
        isLoading: false,
        isSubmitting: false,
        access: state.access,
        roles: state.roles,
        assignments: state.assignments,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> revokeAssignment(
    String assignmentId,
  ) async {
    state = GovernanceState(
      isLoading: state.isLoading,
      isSubmitting: true,
      access: state.access,
      roles: state.roles,
      assignments: state.assignments,
      errorMessage: null,
    );

    try {
      await _repository.revokeAssignment(
        assignmentId,
      );
      await load();
      return true;
    } catch (error) {
      state = GovernanceState(
        isLoading: false,
        isSubmitting: false,
        access: state.access,
        roles: state.roles,
        assignments: state.assignments,
        errorMessage: error.toString(),
      );
      return false;
    }
  }
}
