import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Arka plan (Background/Terminated) FCM bildirim yakalayıcısı.
/// Kural 3 (%20 devamsızlık aşımı uyarısı) ve Modül 2.4 (Anlık Kriz Yayını)
/// bildirimlerini arka planda da işler.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'Background FCM Message received [${message.messageId}]: ${message.data}',
  );
}

/// Firebase Cloud Messaging (FCM) ve flutter_local_notifications kurulumunu yapar.
/// Sınıf/Ders bazlı Topic aboneliklerini (topic_all_campus, topic_course_101 vb.) yönetir.
/// Kural 3 (%20 devamsızlık aşımı uyarısı) ve Modül 2.4 (Anlık Kriz Yayını)
/// bildirimlerini ön planda ve arka planda gösterir.
class FcmNotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const String defaultChannelId = 'edupulse_general_channel';
  static const String defaultChannelName = 'EduPulse Bildirimleri';
  static const String crisisChannelId = 'edupulse_crisis_channel';
  static const String crisisChannelName = 'EduPulse Acil Kriz Yayınları';
  static const String absenceAlertChannelId = 'edupulse_absence_alert_channel';
  static const String absenceAlertChannelName =
      'EduPulse Devamsızlık Sınırı Uyarıları';

  static const String topicAllCampus = 'topic_all_campus';
  static const String topicCrisisBroadcast = 'crisis_broadcast';

  static String courseTopic(String courseId) {
    final sanitized = courseId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
    return sanitized.startsWith('topic_course_')
        ? sanitized
        : 'topic_course_$sanitized';
  }

  String? _latestRegistrationId;
  final Set<String> _subscribedCourseTopics = <String>{};

  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  FcmNotificationService({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  Set<String> get subscribedCourseTopics =>
      Set.unmodifiable(_subscribedCourseTopics);

  Future<void> initialize() async {
    await requestPermission();
    await _initLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _firebaseMessaging.onRegistered.listen((id) {
      _latestRegistrationId = id;
    });
    await _firebaseMessaging.register();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    await subscribeToTopic(topicAllCampus);
    await subscribeToTopic(topicCrisisBroadcast);
  }

  Future<NotificationSettings> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings;
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final payloadMap =
                jsonDecode(response.payload!) as Map<String, dynamic>;
            _notificationTapController.add(payloadMap);
          } catch (_) {
            _notificationTapController.add({'rawPayload': response.payload});
          }
        }
      },
    );

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          defaultChannelId,
          defaultChannelName,
          description: 'Genel ders, ödev ve yoklama bildirimleri',
          importance: Importance.high,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          crisisChannelId,
          crisisChannelName,
          description: 'Modül 2.4: Anlık kriz ve acil durum yayınları',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          absenceAlertChannelId,
          absenceAlertChannelName,
          description: 'Kural 3: %20 devamsızlık sınırı aşımı uyarıları',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final isCrisis = data['type'] == 'urgent' || data['isCrisis'] == 'true';
    final isAbsenceWarning =
        data['type'] == 'absence_warning' || data['isAbsenceAlert'] == 'true';

    final title = notification?.title ??
        data['title']?.toString() ??
        (isCrisis
            ? 'ACİL KRİZ YAYINI'
            : isAbsenceWarning
                ? 'Kritik Devamsızlık Riski!'
                : 'EduPulse');
    final body = notification?.body ?? data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) return;

    showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: jsonEncode(data),
      isCrisis: isCrisis,
      isAbsenceAlert: isAbsenceWarning,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _notificationTapController.add(message.data);
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isCrisis = false,
    bool isAbsenceAlert = false,
  }) async {
    final channelId = isCrisis
        ? crisisChannelId
        : isAbsenceAlert
            ? absenceAlertChannelId
            : defaultChannelId;
    final channelName = isCrisis
        ? crisisChannelName
        : isAbsenceAlert
            ? absenceAlertChannelName
            : defaultChannelName;

    final isHighPriority = isCrisis || isAbsenceAlert;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: isHighPriority ? Importance.max : Importance.high,
      priority: isHighPriority ? Priority.max : Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Kural 3: %20 devamsızlık aşımı uyarısı ("Kritik Devamsızlık Riski!") bildirimi gösterir.
  Future<void> showAbsenceLimitWarningNotification({
    required String courseName,
    required double absencePercentage,
    String? studentId,
    int? absentHours,
    int? maxAllowedHours,
  }) async {
    final percentText = (absencePercentage * 100).toStringAsFixed(0);
    final detailText = (absentHours != null && maxAllowedHours != null)
        ? ' ($absentHours/$maxAllowedHours saat)'
        : '';

    await showLocalNotification(
      id: '${courseName}_${studentId ?? ''}'.hashCode,
      title: 'Kritik Devamsızlık Riski!',
      body:
          '$courseName dersinde devamsızlık oranınız %$percentText seviyesine ulaştı (%20 sınırı aşıldı)$detailText.',
      payload: jsonEncode({
        'type': 'absence_warning',
        'isAbsenceAlert': 'true',
        'courseName': courseName,
        'absencePercentage': absencePercentage,
        'studentId': ?studentId,
      }),
      isAbsenceAlert: true,
    );
  }

  /// Modül 2.4: İlgili FCM Topic kanalına (topic_all_campus veya topic_course_101)
  /// anlık bildirim / Kriz Yayını tetikler.
  Future<void> triggerTopicNotification({
    required String topic,
    required String title,
    required String body,
    bool isCrisis = false,
    Map<String, dynamic>? extraData,
  }) async {
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: isCrisis ? 'ACİL DUYURU: $title' : title,
      body: body,
      payload: jsonEncode({
        'topic': topic,
        'type': isCrisis ? 'urgent' : 'announcement',
        'isCrisis': isCrisis.toString(),
        ...?extraData,
      }),
      isCrisis: isCrisis,
    );
  }

  /// Modül 2.4: Anlık Kriz Yayını bildirimi gösterir.
  Future<void> showCrisisBroadcastNotification({
    required String title,
    required String message,
    String? courseId,
  }) async {
    final targetTopic = (courseId != null && courseId.isNotEmpty)
        ? courseTopic(courseId)
        : topicAllCampus;

    await triggerTopicNotification(
      topic: targetTopic,
      title: title,
      body: message,
      isCrisis: true,
      extraData: {'courseId': ?courseId},
    );
  }

  /// Sınıf/Ders bazlı Topic aboneliği başlatır (Örn: `topic_course_101`).
  Future<void> subscribeToCourseTopic(String courseId) async {
    final topic = courseTopic(courseId);
    await subscribeToTopic(topic);
    _subscribedCourseTopics.add(topic);
  }

  /// Sınıf/Ders bazlı Topic aboneliğinden çıkar.
  Future<void> unsubscribeFromCourseTopic(String courseId) async {
    final topic = courseTopic(courseId);
    await unsubscribeFromTopic(topic);
    _subscribedCourseTopics.remove(topic);
  }

  Future<String?> getFcmToken() async {
    try {
      if (_latestRegistrationId != null) {
        return _latestRegistrationId;
      }
      await _firebaseMessaging.register();
      return _latestRegistrationId;
    } catch (e) {
      debugPrint('Error getting FCM registration ID: $e');
      return null;
    }
  }

  Stream<String> get onTokenRefresh => _firebaseMessaging.onRegistered;

  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  void dispose() {
    _notificationTapController.close();
  }
}
