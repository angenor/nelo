import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import 'router.dart';

/// Main application widget
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Wrap with MultiBlocProvider when BLoCs are added
    // return MultiBlocProvider(
    //   providers: [
    //     BlocProvider(create: (_) => getIt<AuthBloc>()),
    //   ],
    //   child: _buildMaterialApp(),
    // );
    return _buildMaterialApp();
  }

  Widget _buildMaterialApp() {
    return MaterialApp.router(
      title: 'NELO',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light,

      // Router
      routerConfig: AppRouter.router,

      // Localization (to be configured)
      // localizationsDelegates: const [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('fr', 'FR'),
      // ],
      // locale: const Locale('fr', 'FR'),
    );
  }
}
