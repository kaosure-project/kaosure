import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

final class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kao ID',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
