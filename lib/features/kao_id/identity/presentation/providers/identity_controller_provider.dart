import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/identity_providers.dart';

import '../controllers/identity_controller.dart';

import '../states/identity_state.dart';

final identityControllerProvider =
    StateNotifierProvider<IdentityController, IdentityState>(
  (ref) {
    return IdentityController(
      getDocuments: ref.watch(
        getDocumentsProvider,
      ),
      deleteDocument: ref.watch(
        deleteDocumentProvider,
      ),
      uploadDocument: ref.watch(
        uploadDocumentProvider,
      ),
    );
  },
);