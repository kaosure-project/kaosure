import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

final class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final initialRoute = Uri.base.path.isEmpty
        ? AppRouter.initialRoute
        : Uri.base.path;

    return MaterialApp(
      title: 'Kao ID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}