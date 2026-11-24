import 'package:flutter/material.dart';

import 'core/settings/font_scale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/navigation_utils.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  fontScaleController.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spicera Workforce',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationUtils.navigatorKey,
      theme: AppTheme.light,
      home: const SplashScreen(),
      builder: (context, child) {
        return ValueListenableBuilder<double>(
          valueListenable: fontScaleController,
          builder: (context, scale, _) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
