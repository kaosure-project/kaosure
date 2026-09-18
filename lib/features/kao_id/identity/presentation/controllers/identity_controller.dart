import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/identity_document.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/get_documents.dart';
import '../../domain/usecases/upload_document.dart';

import '../states/identity_state.dart';

final class IdentityController extends StateNotifier<IdentityState> {
  IdentityController({
    required this._getDocuments,
    required this._deleteDocument,
    required this._uploadDocument,
  }) : super(IdentityState.initial());

  final GetDocuments _getDocuments;
  final DeleteDocument _deleteDocument;
  final UploadDocument _uploadDocument;

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

  Future<void> uploadDocument({
    required IdentityDocument document,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await _uploadDocument(
        document: document,
      );

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