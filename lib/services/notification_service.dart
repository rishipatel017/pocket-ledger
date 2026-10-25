import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/reminder_item.dart';
import '../models/financial_record_item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionGranted = false;

  bool get isPermissionGranted => _permissionGranted;

  static const String _channelId = 'pocketledger_alerts';
  static const String _channelName = 'PocketLedger Alerts';
  static const String _channelDesc =
      'Bill reminders, budget warnings, and FD maturity alerts';

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      final granted =
          await androidImpl.requestNotificationsPermission() ?? false;
      _permissionGranted = granted;
      return granted;
    }

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      _permissionGranted = granted;
      return granted;
    }

    _permissionGranted = true;
    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final enabled = await androidImpl.areNotificationsEnabled() ?? false;
      _permissionGranted = enabled;
      return enabled;
    }
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> showReminderAlert(ReminderItem reminder) async {
    if (!_permissionGranted) return;
    final daysText = reminder.isOverdue
        ? 'OVERDUE'
        : _daysUntilText(reminder.dueDate);
    await _show(
      id: reminder.id.hashCode.abs() % 10000,
      title: 'Bill Due: ${reminder.title}',
      body: 'Rs.${reminder.amount.toStringAsFixed(0)} - $daysText. Tap to mark as paid.',
      payload: 'reminder:${reminder.id}',
      color: Colors.amber,
    );
  }

  Future<void> showBudgetWarning({
    required String categoryName,
    required double spent,
    required double limit,
    required double percent,
  }) async {
    if (!_permissionGranted) return;
    final emoji = percent >= 1.0 ? 'ALERT' : 'WARNING';
    final statusText = percent >= 1.0
        ? 'EXCEEDED! Over budget by Rs.${(spent - limit).toStringAsFixed(0)}'
        : '${(percent * 100).toStringAsFixed(0)}% used - Rs.${(limit - spent).toStringAsFixed(0)} remaining';
    await _show(
      id: ('budget_$categoryName').hashCode.abs() % 10000,
      title: '$emoji Budget Alert: $categoryName',
      body: statusText,
      payload: 'budget:$categoryName',
      color: percent >= 1.0 ? Colors.red : Colors.orange,
    );
  }

  Future<void> showFDMaturityAlert(FinancialRecordItem record) async {
    if (!_permissionGranted) return;
    final daysUntil = record.maturityOrRenewalDate
        .difference(DateTime.now())
        .inDays;
    final typeLabel =
        record.type == FinancialRecordType.fixedDeposit ? 'FD' : 'Policy';
    await _show(
      id: record.id.hashCode.abs() % 10000,
      title: '$typeLabel Maturing: ${record.title}',
      body: daysUntil <= 0
          ? 'Matured today! Check your ${record.institution} account.'
          : 'Matures in $daysUntil days at ${record.institution}. Amount: Rs.${record.maturityAmount?.toStringAsFixed(0) ?? record.principalOrPremium.toStringAsFixed(0)}',
      payload: 'fd:${record.id}',
      color: Colors.teal,
    );
  }

  Future<void> showMonthlyBudgetReminder({
    required String monthName,
    required double? lastMonthLimit,
  }) async {
    if (!_permissionGranted) return;
    final body = lastMonthLimit != null
        ? 'Last month budget was Rs.${lastMonthLimit.toStringAsFixed(0)}. Set your $monthName budget now.'
        : 'Set your monthly spending budget for $monthName to stay on track.';
    await _show(
      id: 9001,
      title: 'Set Budget for $monthName',
      body: body,
      payload: 'monthly_budget',
      color: Colors.blue,
    );
  }

  Future<void> checkAndFireReminders(List<ReminderItem> reminders) async {
    if (!_permissionGranted) return;
    final now = DateTime.now();
    for (final r in reminders) {
      if (!r.isPending && !r.isPostponed) continue;
      final daysUntil = r.dueDate.difference(now).inDays;
      if (daysUntil <= 3) {
        await showReminderAlert(r);
      }
    }
  }

  Future<void> checkAndFireFDAlerts(List<FinancialRecordItem> records) async {
    if (!_permissionGranted) return;
    final now = DateTime.now();
    for (final r in records) {
      if (r.isArchived) continue;
      final daysUntil = r.maturityOrRenewalDate.difference(now).inDays;
      if (daysUntil <= 30) {
        await showFDMaturityAlert(r);
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String payload,
    Color color = Colors.teal,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      color: color,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(body),
    );
    final notifDetails = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notifDetails,
      payload: payload,
    );
  }

  String _daysUntilText(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days == 0) return 'due TODAY';
    if (days == 1) return 'due tomorrow';
    if (days < 0) return 'overdue by ${(-days)} days';
    return 'due in $days days';
  }
}
