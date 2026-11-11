/// Tüm ekranların URL (path) ve isim (name) sabitleri.
class RouteNames {
  RouteNames._();

  // ---- Path ----
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String liveAttendance = '/live-attendance';
  static const String assignments = '/assignments';
  static const String absenceControl = '/absence-control';
  static const String grades = '/grades';
  static const String forum = '/forum';

  /// Sadece eğitmene özel: ödev notlandırma detayı.
  /// Tam yol: /assignments/grading/:submissionId
  static const String submissionGradingBase = '/assignments/grading';
  static const String submissionGradingParam = 'submissionId';

  static String submissionGradingPath(String submissionId) =>
      '$submissionGradingBase/$submissionId';

  /// Forum soru detayı. Tam yol: /forum/question/:questionId
  /// (Rota app_router.dart'a /forum altına alt rota olarak eklenecek.)
  static const String forumQuestionBase = '/forum/question';
  static const String forumQuestionParam = 'questionId';

  static String forumQuestionPath(String questionId) => '$forumQuestionBase/$questionId';

  // ---- Name ----
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String forgotPasswordName = 'forgot-password';
  static const String homeName = 'home';
  static const String scheduleName = 'schedule';
  static const String liveAttendanceName = 'live-attendance';
  static const String assignmentsName = 'assignments';
  static const String absenceControlName = 'absence-control';
  static const String gradesName = 'grades';
  static const String forumName = 'forum';
  static const String submissionGradingName = 'submission-grading';
}
