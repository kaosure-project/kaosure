import 'package:equatable/equatable.dart';

import '../../domain/entities/identity_document.dart';

final class IdentityState extends Equatable {
  const IdentityState({
    required this.documents,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<IdentityDocument> documents;

  final bool isLoading;

  final String? errorMessage;

  factory IdentityState.initial() {
    return const IdentityState(
      documents: [],
      isLoading: false,
      errorMessage: null,
    );
  }

  IdentityState copyWith({
    List<IdentityDocument>? documents,
    bool? isLoading,
    String? errorMessage,
  }) {
    return IdentityState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        documents,
        isLoading,
        errorMessage,
      ];
}