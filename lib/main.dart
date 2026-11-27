import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/kiosk_device_controller.dart';
import 'core/settings/font_scale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/navigation_utils.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  fontScaleController.load();
  authController.load();
  kioskDeviceController.load();
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
                onTapDown: (details) {
                  // Only unfocus when the tap didn't land on an editable
                  // field at all — checking what was actually hit avoids
                  // racing with that field's own focus request, which is
                  // what caused the keyboard to flicker closed/reopen when
                  // tapping directly from one field to the next.
                  final result = BoxHitTestResult();
                  WidgetsBinding.instance.hitTestInView(
                    result,
                    details.globalPosition,
                    View.of(context).viewId,
                  );
                  final tappedEditable = result.path.any(
                    (entry) => entry.target is RenderEditable,
                  );
                  if (!tappedEditable) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                },
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
