import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/bootstrap_controller.dart';
import '../states/bootstrap_state.dart';

final bootstrapControllerProvider =
    StateNotifierProvider<
        BootstrapController,
        BootstrapStatus>(
  (ref) => BootstrapController(ref),
);