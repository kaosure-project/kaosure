import 'package:equatable/equatable.dart';

final class GovernanceRole extends Equatable {
  const GovernanceRole({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.isSystem,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isSystem;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        description,
        isSystem,
      ];
}
