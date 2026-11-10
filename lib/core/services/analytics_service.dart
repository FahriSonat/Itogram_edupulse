import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics ve Crashlytics servisidir.
/// Kritik aksiyonları (Yoklama başlatıldı, Ödev yüklendi, Kriz bildirimi atıldı, Rol değiştirildi)
/// özel event olarak loglar.
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics? _crashlytics;

  AnalyticsService({
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
  })  : _analytics = analytics ?? FirebaseAnalytics.instance,
        _crashlytics = kIsWeb
            ? null
            : (crashlytics ?? FirebaseCrashlytics.instance);

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    if (!kIsWeb && _crashlytics != null) {
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = _crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  Future<void> setUserIdentity({
    required String userId,
    String? role,
    String? department,
  }) async {
    await _analytics.setUserId(id: userId);
    if (role != null) {
      await _analytics.setUserProperty(name: 'user_role', value: role);
    }
    if (department != null) {
      await _analytics.setUserProperty(name: 'department', value: department);
    }

    if (!kIsWeb && _crashlytics != null) {
      await _crashlytics.setUserIdentifier(userId);
      if (role != null) {
        await _crashlytics.setCustomKey('user_role', role);
      }
    }
  }

  Future<void> clearUserIdentity() async {
    await _analytics.setUserId(id: null);
    if (!kIsWeb && _crashlytics != null) {
      await _crashlytics.setUserIdentifier('');
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Analytics logScreenView error: $e');
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Analytics logEvent ($name) error: $e');
    }
  }

  Future<void> logLogin({String loginMethod = 'student_no_or_email'}) async {
    await logEvent(
      name: 'login',
      parameters: {'method': loginMethod},
    );
  }

  /// Kritik Aksiyon 1: Yoklama başlatıldı
  Future<void> logAttendanceStarted({
    required String courseId,
    required String sessionId,
    required String instructorId,
  }) async {
    await logEvent(
      name: 'attendance_started',
      parameters: {
        'course_id': courseId,
        'session_id': sessionId,
        'instructor_id': instructorId,
      },
    );
  }

  Future<void> logAttendanceSubmitted({
    required String courseId,
    required String sessionId,
    required String method,
  }) async {
    await logEvent(
      name: 'attendance_submitted',
      parameters: {
        'course_id': courseId,
        'session_id': sessionId,
        'method': method,
      },
    );
  }

  /// Kritik Aksiyon 2: Ödev yüklendi
  Future<void> logAssignmentSubmitted({
    required String assignmentId,
    required bool isLate,
    String? fileName,
  }) async {
    await logEvent(
      name: 'assignment_uploaded',
      parameters: {
        'assignment_id': assignmentId,
        'is_late': isLate ? 1 : 0,
        'file_name': ?fileName,
      },
    );
  }

  /// Kritik Aksiyon 3: Kriz bildirimi atıldı
  Future<void> logCrisisBroadcastSent({
    required String senderId,
    required String title,
    String? targetCourseId,
  }) async {
    await logEvent(
      name: 'crisis_broadcast_sent',
      parameters: {
        'sender_id': senderId,
        'title': title,
        'target_course_id': targetCourseId ?? 'all',
      },
    );
  }

  /// Kritik Aksiyon 4: Rol değiştirildi
  Future<void> logRoleChanged({
    required String previousRole,
    required String newRole,
    String? userId,
  }) async {
    await logEvent(
      name: 'role_changed',
      parameters: {
        'previous_role': previousRole,
        'new_role': newRole,
        'user_id': ?userId,
      },
    );
  }

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    debugPrint('Recorded Error [$reason]: $exception');
    if (!kIsWeb && _crashlytics != null) {
      await _crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    }
  }
}
