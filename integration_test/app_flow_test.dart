import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocketledger/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketledger/services/storage_service.dart';
import 'package:pocketledger/services/notification_service.dart';
import 'package:pocketledger/state/app_state.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete app flow test', (WidgetTester tester) async {
    // Initialize storage and mark as seeded to prevent demo data
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    await storage.markSeeded();
    
    final appState = AppState(storage);
    await appState.init();
    
    final notificationService = NotificationService();

    await tester.pumpWidget(app.PocketLedgerApp(
      appState: appState,
      notificationService: notificationService,
    ));
    await tester.pumpAndSettle();

    // Test 1: App launches successfully
    expect(find.text('PocketLedger'), findsWidgets);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Test 2: Navigate to Transactions screen
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    expect(find.text('Transactions'), findsWidgets);

    // Test 3: Navigate back to Home
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);

    // Test 4: Navigate to Insights
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Insights'), findsWidgets);

    // Test 5: Navigate to Calendar
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsWidgets);

    // Test 6: Navigate to Settings
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);

    // Test 7: Navigate back to Home
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
  });
}
