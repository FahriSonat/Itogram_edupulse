class FirestorePaths {
  static const String users = 'users';
  static const String announcements = 'announcements';
  static const String courses = 'courses';
  static const String assignments = 'assignments';
  static const String forumQuestions = 'forum_questions';

  static String attendanceSessions(String courseId) => 'courses/$courseId/attendance_sessions';
  static String attendanceRecords(String courseId) => 'courses/$courseId/attendance_records';
  static String grades(String courseId) => 'courses/$courseId/grades';
  static String submissions(String assignmentId) => 'assignments/$assignmentId/submissions';
  static String forumAnswers(String questionId) => 'forum_questions/$questionId/answers';
}