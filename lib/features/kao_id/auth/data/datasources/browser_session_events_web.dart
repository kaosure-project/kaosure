import 'package:web/web.dart' as web;

/// A `null` key means the whole storage was cleared.
Stream<void> removals(String storageKey) => web.EventStreamProviders.storageEvent
    .forTarget(web.window)
    .where(
      (event) =>
          (event.key == null || event.key == storageKey) &&
          event.newValue == null,
    );
