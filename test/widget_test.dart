import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketledger/main.dart';
import 'package:pocketledger/services/storage_service.dart';
import 'package:pocketledger/services/notification_service.dart';
import 'package:pocketledger/state/app_state.dart';

void main() {
  testWidgets('PocketLedger launches and renders home screen correctly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    
    // Mark as seeded to prevent demo data in tests
    await storage.markSeeded();
    
    final appState = AppState(storage);
    await appState.init();
    
    // Don't initialize notification service in tests - it requires platform
    final notificationService = NotificationService();

    await tester.pumpWidget(PocketLedgerApp(
      appState: appState,
      notificationService: notificationService,
    ));
    await tester.pumpAndSettle();

    expect(find.text('PocketLedger'), findsWidgets);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Insights'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
