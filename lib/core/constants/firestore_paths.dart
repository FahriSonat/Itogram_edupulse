/// [FirestorePaths] tüm koleksiyon adlarını tek yerde toplar.
///
/// Uygulama şu an verileri cihazdaki yerel veritabanında
/// ([LocalStorageService]) aynı koleksiyon adlarıyla saklar. İleride Cloud
/// Firestore'a geçildiğinde aynı yollar kullanılabilir.
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String courses = 'courses';
  static const String announcements = 'announcements';
  static const String assignments = 'assignments';
  static const String submissions = 'submissions';
  static const String attendanceSessions = 'attendance_sessions';
  static const String absenceRecords = 'absence_records';
  static const String grades = 'grades';
  static const String forumQuestions = 'forum_questions';
  static const String forumAnswers = 'forum_answers';
  static const String notifications = 'notifications';

  static const List<String> all = [
    users,
    courses,
    announcements,
    assignments,
    submissions,
    attendanceSessions,
    absenceRecords,
    grades,
    forumQuestions,
    forumAnswers,
    notifications,
  ];
}
