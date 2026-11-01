import 'browser_session_events_stub.dart'
    if (dart.library.js_interop) 'browser_session_events_web.dart'
    as platform;

/// Fires when another tab of this browser signs out of Kao ID: Supabase Auth
/// removes its stored session (`sb-<project>-auth-token`), which every other
/// tab hears as a `storage` event. Never fires off the web.
Stream<void> kaoIdSignedOutElsewhere(Uri supabaseUrl) =>
    platform.removals('sb-${supabaseUrl.host.split('.').first}-auth-token');
