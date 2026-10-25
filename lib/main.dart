import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/loading_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize storage and app state
  final storage = await StorageService.init();
  final appState = AppState(storage);
  await appState.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  // Request permission
  await notificationService.requestPermission();

  runApp(PocketLedgerApp(
    appState: appState,
    notificationService: notificationService,
  ));
}

class PocketLedgerApp extends StatelessWidget {
  final AppState appState;
  final NotificationService notificationService;

  const PocketLedgerApp({
    super.key,
    required this.appState,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        ThemeMode themeMode;
        switch (appState.settings.themeMode) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'system':
            themeMode = ThemeMode.system;
            break;
          case 'dark':
          default:
            themeMode = ThemeMode.dark;
            break;
        }

        return MaterialApp(
          title: 'PocketLedger',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: LoadingScreen(
            child: PinLockScreen(
              appState: appState,
              child: MainNavigationScreen(
                appState: appState,
                notificationService: notificationService,
              ),
            ),
          ),
        );
      },
    );
  }
}
