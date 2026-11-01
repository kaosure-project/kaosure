import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/bootstrap.dart';

Future<void> main() async {
  // Supabase OAuth sends members to /oauth/consent?authorization_id=..., which
  // only reaches the router as a path with path URL strategy.
  usePathUrlStrategy();
  await bootstrap();
}
