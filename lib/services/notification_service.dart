import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../app_router.dart';

/// Must be a top-level function so Android can run it in the background.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'questify_reminders';
  static const _channelName = 'Quest reminders';
  static const _channelDescription =
      'Reminders and updates about your quests';

  static const _testReminderId = 999001;

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _openFromPayload(response.payload),
    );

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    try {
      await _android?.requestNotificationsPermission();
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp
        .listen((m) => _openFromPayload(_payloadFromMessage(m)));
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) registerToken();
    });

    await _handleLaunchTaps();
  }

  // ---- FCM token ----------------------------------------------------------

  Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM token: $token');
      await _saveToken(token);
    } catch (e) {
      debugPrint('Could not get FCM token: $e');
    }
  }

  Future<void> _saveToken(String? token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || token == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Could not save FCM token: $e');
    }
  }

  /// Call this BEFORE signing out.
  Future<void> unregisterToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (uid == null || token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Could not remove FCM token: $e');
    }
  }

  // ---- Receiving and tapping ----------------------------------------------

  void _onForegroundMessage(RemoteMessage message) {
    showNotification(
      title: message.notification?.title ?? 'Questify',
      body: message.notification?.body ?? 'You have a new quest update!',
      payload: _payloadFromMessage(message),
    );
  }

  String? _payloadFromMessage(RemoteMessage message) {
    final questId = message.data['questId'];
    return questId == null ? null : 'quest:$questId';
  }

  Future<void> _handleLaunchTaps() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        _openFromPayload(details!.notificationResponse?.payload);
      }
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _openFromPayload(_payloadFromMessage(initial));
    } catch (e) {
      debugPrint('Could not read launch notification: $e');
    }
  }

  void _openFromPayload(String? payload) {
    if (payload == null || !payload.startsWith('quest:')) return;
    final questId = payload.substring('quest:'.length);
    if (questId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appRouter.push('/quest/$questId');
    });
  }

  // ---- Showing and scheduling ---------------------------------------------

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  int _newId() => DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  int _idForQuest(String questId) {
    var hash = 17;
    for (final unit in questId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int? id,
    String? payload,
  }) async {
    try {
      await _plugin.show(id ?? _newId(), title, body, _details,
          payload: payload);
    } catch (e) {
      debugPrint('Could not show notification: $e');
    }
  }

  Future<void> showQuestCompletedNotification({
    required String questTitle,
    required int currentCount,
    required int targetCount,
  }) {
    return showNotification(
      title: 'Quest completed! 🎉',
      body: 'You completed "$questTitle" ($currentCount/$targetCount)',
    );
  }

  Future<void> showProgressReminder({
    required String questTitle,
    required String description,
  }) {
    return showNotification(
      title: 'Reminder: continue your quest',
      body: description.isEmpty
          ? 'Don\'t forget about "$questTitle"'
          : 'Don\'t forget about "$questTitle"\n$description',
    );
  }

  /// Schedules a notification at an exact moment. Uses exact alarms when the
  /// phone allows them (on time), otherwise inexact alarms (can be a few
  /// minutes late). Throws if the plugin refuses, so callers can report it.
  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.UTC),
      _details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// One-time reminder 24 hours before the deadline (or 1 hour before, if
  /// the deadline is closer than a day).
  Future<void> scheduleDeadlineReminder({
    required String questId,
    required String questTitle,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    var when = deadline.subtract(const Duration(hours: 24));
    if (!when.isAfter(now)) when = deadline.subtract(const Duration(hours: 1));
    if (!when.isAfter(now)) return;

    try {
      await _scheduleAt(
        id: _idForQuest(questId),
        title: 'Quest due soon',
        body: '"$questTitle" is almost due.',
        when: when,
        payload: 'quest:$questId',
      );
    } catch (e) {
      debugPrint('Could not schedule deadline reminder: $e');
    }
  }

  /// One-time reminder at the exact moment chosen by the user.
  Future<void> scheduleQuestReminder({
    required String questId,
    required String questTitle,
    required DateTime when,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    try {
      await _scheduleAt(
        id: _idForQuest(questId),
        title: 'Quest reminder',
        body: 'Time to work on "$questTitle".',
        when: when,
        payload: 'quest:$questId',
      );
    } catch (e) {
      debugPrint('Could not schedule quest reminder: $e');
    }
  }

  Future<void> cancelQuestReminder(String questId) async {
    try {
      await _plugin.cancel(_idForQuest(questId));
    } catch (e) {
      debugPrint('Could not cancel reminder: $e');
    }
  }

  // ---- Diagnostics (used by Settings) -------------------------------------

  /// Shows a notification immediately. Returns null on success or an error.
  Future<String?> sendTestNotification() async {
    try {
      await _plugin.show(_newId(), 'Questify test',
          'Notifications are working on this device.', _details);
      return null;
    } catch (e) {
      return '$e';
    }
  }

  /// Schedules a test reminder. Returns null on success or an error.
  Future<String?> scheduleTestReminder({int seconds = 30}) async {
    try {
      await _scheduleAt(
        id: _testReminderId,
        title: 'Test reminder',
        body: 'This reminder was scheduled $seconds seconds ago.',
        when: DateTime.now().add(Duration(seconds: seconds)),
      );
      return null;
    } catch (e) {
      return '$e';
    }
  }

  /// Whether the phone currently allows exact alarms.
  Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  Future<bool> notificationsAllowed() async =>
      await _android?.areNotificationsEnabled() ?? false;

  Future<int> pendingReminderCount() async =>
      (await _plugin.pendingNotificationRequests()).length;
}

final notificationServiceProvider =
Provider((ref) => NotificationService.instance);
