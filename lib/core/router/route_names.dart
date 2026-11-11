/// [RouteNames] uygulamadaki tüm adlandırılmış rotalar.
abstract final class RouteNames {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Ana kabuk (alt menü sekmeleri)
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String assignments = '/assignments';
  static const String forum = '/forum';
  static const String grades = '/grades';
  static const String profile = '/profile';

  // Yan menüden açılan modüller
  static const String liveAttendance = '/live-attendance';
  static const String absenceControl = '/absence-control';

  // Detay sayfaları
  static const String submissionGrading = '/assignments/grading';
  static const String forumQuestionDetail = '/forum/question';
}
