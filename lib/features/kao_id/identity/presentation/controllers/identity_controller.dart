import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/get_documents.dart';
import '../../domain/usecases/submit_verification.dart';

import '../states/identity_state.dart';

final class IdentityController extends StateNotifier<IdentityState> {
  IdentityController({
    required GetDocuments getDocuments,
    required SubmitVerification submitVerification,
    required DeleteDocument deleteDocument,
  })  : _getDocuments = getDocuments,
        _submitVerification = submitVerification,
        _deleteDocument = deleteDocument,
        super(IdentityState.initial());

  final GetDocuments _getDocuments;
  final SubmitVerification _submitVerification;
  final DeleteDocument _deleteDocument;

  Future<void> loadDocuments() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final documents = await _getDocuments();

      state = state.copyWith(
        documents: documents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() {
    return loadDocuments();
  }

  Future<void> submitVerification() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await _submitVerification();

      await loadDocuments();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteDocument({
    required String documentId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await _deleteDocument(documentId);

      await loadDocuments();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}