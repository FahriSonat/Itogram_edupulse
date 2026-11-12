// Firebase'e bağlanmayan, bellekte çalışan repository taklitleri.
// Her biri "Firestore snapshots()" davranışını broadcast StreamController ile
// taklit eder: yazma işlemleri anında dinleyicilere yeni liste olarak düşer.

import 'dart:async';

import 'package:itogram_edupulse/core/enums/attendance_status.dart';
import 'package:itogram_edupulse/core/enums/submission_status.dart';
import 'package:itogram_edupulse/core/error/exceptions.dart';
import 'package:itogram_edupulse/features/announcements/domain/entities/announcement_entity.dart';
import 'package:itogram_edupulse/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:itogram_edupulse/features/assignments/domain/entities/assignment_entity.dart';
import 'package:itogram_edupulse/features/assignments/domain/entities/submission_entity.dart';
import 'package:itogram_edupulse/features/assignments/domain/repositories/assignment_repository.dart';
import 'package:itogram_edupulse/features/attendance/domain/entities/attendance_session_entity.dart';
import 'package:itogram_edupulse/features/attendance/domain/entities/student_absence_record_entity.dart';
import 'package:itogram_edupulse/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:itogram_edupulse/features/forum/domain/entities/forum_answer_entity.dart';
import 'package:itogram_edupulse/features/forum/domain/entities/forum_question_entity.dart';
import 'package:itogram_edupulse/features/forum/domain/repositories/forum_repository.dart';
import 'package:itogram_edupulse/features/grades/domain/entities/course_grade_entity.dart';
import 'package:itogram_edupulse/features/grades/domain/repositories/grades_repository.dart';
import 'package:itogram_edupulse/features/schedule/domain/entities/course_schedule_entity.dart';
import 'package:itogram_edupulse/features/schedule/domain/repositories/schedule_repository.dart';

/// Canlı liste: her değişiklikte güncel kopyayı yayınlar; yeni dinleyici
/// önce mevcut değeri alır (Firestore snapshots davranışı).
class LiveList<T> {
  LiveList([List<T>? initial]) : items = <T>[...?initial];

  final List<T> items;
  final StreamController<List<T>> _controller = StreamController<List<T>>.broadcast();
  Object? streamError;

  Stream<List<T>> watch([bool Function(T)? where]) async* {
    final err = streamError;
    if (err != null) throw err;
    List<T> view() => where == null ? List<T>.of(items) : items.where(where).toList();
    yield view();
    yield* _controller.stream.map((_) => view());
  }

  void changed() => _controller.add(items);
}

const CourseScheduleEntity mobileCourse = CourseScheduleEntity(
  courseId: 'c-mob',
  courseCode: 'MOB101',
  courseName: 'Mobil Programlama',
  instructorName: 'Fahri Hoca',
  roomLocation: 'D-107',
  dayOfWeek: 1,
  startTime: '10:30',
  endTime: '12:00',
);

const CourseScheduleEntity algoCourse = CourseScheduleEntity(
  courseId: 'c-alg',
  courseCode: 'ALG201',
  courseName: 'Algoritmalar',
  instructorName: 'Ahmet Hoca',
  roomLocation: 'A-204',
  dayOfWeek: 3,
  startTime: '13:00',
  endTime: '15:00',
);

// ------------------------------------------------------------------ Schedule
class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository([List<CourseScheduleEntity>? courses])
      : courses = LiveList<CourseScheduleEntity>(courses ?? const [mobileCourse, algoCourse]);

  final LiveList<CourseScheduleEntity> courses;
  Object? error;
  int _id = 0;

  @override
  Stream<List<CourseScheduleEntity>> watchWeeklySchedule() => courses.watch();

  @override
  Future<void> addCourse(CourseScheduleEntity course) async {
    if (error != null) throw error!;
    courses.items.add(CourseScheduleEntity(
      courseId: 'new-${_id++}',
      courseCode: course.courseCode,
      courseName: course.courseName,
      instructorName: course.instructorName,
      roomLocation: course.roomLocation,
      dayOfWeek: course.dayOfWeek,
      startTime: course.startTime,
      endTime: course.endTime,
    ));
    courses.changed();
  }

  @override
  Future<void> updateCourse(CourseScheduleEntity course) async {
    if (error != null) throw error!;
    final i = courses.items.indexWhere((c) => c.courseId == course.courseId);
    if (i >= 0) courses.items[i] = course;
    courses.changed();
  }

  @override
  Future<void> removeCourse(String courseId) async {
    if (error != null) throw error!;
    courses.items.removeWhere((c) => c.courseId == courseId);
    courses.changed();
  }
}

// ---------------------------------------------------------------- Attendance
class FakeAttendanceRepository implements AttendanceRepository {
  final List<AttendanceSessionEntity> generated = <AttendanceSessionEntity>[];
  final Map<String, StreamController<AttendanceSessionEntity?>> rosters = {};
  final List<String> submittedCodes = <String>[];
  final List<(String, String, AttendanceStatus)> updates = [];
  final List<String> evaluated = <String>[];
  final LiveList<StudentAbsenceRecordEntity> classRecords = LiveList<StudentAbsenceRecordEntity>();
  final Map<String, StudentAbsenceRecordEntity> studentRecords = {};

  /// submitLiveAttendance davranışı: null → başarılı.
  Object? submitError;
  Map<String, AttendanceStatus> initialStatuses = const {'uid-1': AttendanceStatus.absent};

  @override
  Future<AttendanceSessionEntity> generateAttendanceSession(String courseId) async {
    final now = DateTime.now();
    final n = generated.length + 1;
    final session = AttendanceSessionEntity(
      sessionId: 'sess-$n',
      courseId: courseId,
      qrCodeToken: 'EDUPULSE|$courseId|sess-$n|${1000 + n}',
      pinCode: '${1000 + n}',
      createdAt: now,
      expiresAt: now.add(const Duration(seconds: 60)),
      isActive: true,
      studentStatusMap: Map<String, AttendanceStatus>.of(initialStatuses),
    );
    generated.add(session);
    return session;
  }

  @override
  Stream<AttendanceSessionEntity?> watchLiveAttendanceRoster(String sessionId) =>
      (rosters[sessionId] ??= StreamController<AttendanceSessionEntity?>.broadcast()).stream;

  @override
  Future<void> submitLiveAttendance({required String sessionId, required String studentUid, required String code}) async {
    submittedCodes.add(code);
    if (submitError != null) throw submitError!;
  }

  @override
  Future<void> updateAttendanceRecord({
    required String courseId,
    required String studentUid,
    required AttendanceStatus status,
  }) async {
    updates.add((courseId, studentUid, status));
  }

  @override
  Future<StudentAbsenceRecordEntity> evaluateAbsenceRisk(String courseId, String studentUid) async {
    evaluated.add('$courseId/$studentUid');
    return studentRecords['$courseId/$studentUid'] ?? absenceRecord(courseId: courseId, uid: studentUid, absent: 0);
  }

  @override
  Stream<List<StudentAbsenceRecordEntity>> watchClassAbsenceRecords(String courseId) =>
      classRecords.watch((r) => r.courseId == courseId);

  @override
  Future<StudentAbsenceRecordEntity> getStudentAbsenceRecord(String courseId, String studentUid) async {
    final r = studentRecords['$courseId/$studentUid'];
    if (r == null) throw const ServerException('kayıt yok');
    return r;
  }
}

StudentAbsenceRecordEntity absenceRecord({
  required String courseId,
  required String uid,
  required int absent,
  int total = 40,
  String name = 'Merve Kedersiz',
  String courseName = 'Mobil Programlama',
}) {
  final pct = absent / total * 100;
  return StudentAbsenceRecordEntity(
    studentUid: uid,
    studentName: name,
    studentNo: '2026${uid.hashCode.abs() % 10000}',
    courseId: courseId,
    courseName: courseName,
    totalCourseHours: total,
    absentHours: absent,
    absencePercentage: pct,
    isCriticalRisk: pct >= 20,
  );
}

// --------------------------------------------------------------- Assignments
class FakeAssignmentRepository implements AssignmentRepository {
  final LiveList<AssignmentEntity> assignments = LiveList<AssignmentEntity>();
  final LiveList<SubmissionEntity> submissions = LiveList<SubmissionEntity>();
  final List<Map<String, Object?>> grades = [];
  final List<String> uploadedAudio = [];
  Object? error;

  /// Yükleme ilerleme adımları (0.0 → 1.0).
  List<double> progressSteps = const [0.25, 0.75, 1.0];

  @override
  Stream<List<AssignmentEntity>> watchAssignments(String courseId) => assignments.watch((a) => a.courseId == courseId);

  @override
  Future<void> createAssignment(AssignmentEntity assignment) async {
    if (error != null) throw error!;
    assignments.items.add(assignment);
    assignments.changed();
  }

  @override
  Stream<List<SubmissionEntity>> watchSubmissions(String assignmentId) =>
      submissions.watch((s) => s.assignmentId == assignmentId);

  @override
  Future<void> uploadSubmission(SubmissionEntity submission) async {
    if (error != null) throw error!;
    submissions.items
      ..removeWhere((s) => s.submissionId == submission.submissionId && s.assignmentId == submission.assignmentId)
      ..add(submission);
    submissions.changed();
  }

  @override
  Stream<double> uploadSubmissionWithProgress(SubmissionEntity submission) async* {
    if (error != null) throw error!;
    for (final p in progressSteps) {
      yield p;
    }
    await uploadSubmission(submission);
  }

  @override
  Future<void> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required double rawScore,
    String? writtenFeedback,
    String? audioFeedbackUrl,
  }) async {
    if (error != null) throw error!;
    grades.add({
      'assignmentId': assignmentId,
      'submissionId': submissionId,
      'rawScore': rawScore,
      'writtenFeedback': writtenFeedback,
      'audioFeedbackUrl': audioFeedbackUrl,
    });
  }

  @override
  Future<String> uploadAudioFeedback({
    required String assignmentId,
    required String submissionId,
    required String localFilePath,
  }) async {
    uploadedAudio.add(localFilePath);
    return 'https://storage/audio/$submissionId.m4a';
  }
}

SubmissionEntity submissionOf({
  required String assignmentId,
  String uid = 'uid-student',
  String name = 'Merve Kedersiz',
  bool late = false,
  SubmissionStatus? status,
}) =>
    SubmissionEntity(
      submissionId: uid,
      assignmentId: assignmentId,
      studentUid: uid,
      studentName: name,
      fileUrl: 'https://storage/odev.pdf',
      fileName: 'odev.pdf',
      submittedAt: DateTime(2026, 11, 12, 10),
      status: status ?? (late ? SubmissionStatus.late : SubmissionStatus.submitted),
      isLatePenaltyApplied: late,
    );

// -------------------------------------------------------------------- Grades
class FakeGradesRepository implements GradesRepository {
  final LiveList<CourseGradeEntity> grades = LiveList<CourseGradeEntity>();
  List<({String uid, String name, String studentNo})> students = const [
    (uid: 'uid-student', name: 'Merve Kedersiz', studentNo: '20261234'),
    (uid: 'uid-2', name: 'Ayberk Erdem', studentNo: '20265678'),
  ];
  Object? error;

  @override
  Stream<List<CourseGradeEntity>> watchStudentGrades(String studentUid) =>
      grades.watch((g) => g.studentUid == studentUid);

  @override
  Stream<List<CourseGradeEntity>> watchCourseGrades(String courseId) => grades.watch((g) => g.courseId == courseId);

  @override
  Future<void> manageStudentGrade(CourseGradeEntity grade) async {
    if (error != null) throw error!;
    grades.items
      ..removeWhere((g) => g.gradeId == grade.gradeId && g.courseId == grade.courseId)
      ..add(grade);
    grades.changed();
  }

  @override
  Future<void> deleteStudentGrade(String gradeId, String courseId) async {
    if (error != null) throw error!;
    grades.items.removeWhere((g) => g.gradeId == gradeId && g.courseId == courseId);
    grades.changed();
  }

  @override
  Future<List<({String uid, String name, String studentNo})>> getRegisteredStudents() async => students;
}

// --------------------------------------------------------------------- Forum
class FakeForumRepository implements ForumRepository {
  final LiveList<ForumQuestionEntity> questions = LiveList<ForumQuestionEntity>();
  final Map<String, LiveList<ForumAnswerEntity>> answers = {};
  final List<(String, String)> resolved = [];
  Object? error;
  int _id = 0;

  @override
  Stream<List<ForumQuestionEntity>> watchForumQuestions({String? courseTag, String? topicTag}) => questions.watch(
        (q) => (courseTag == null || q.courseTag == courseTag) && (topicTag == null || q.topicTag == topicTag),
      );

  @override
  Future<void> askQuestionWithPhoto(ForumQuestionEntity question) async {
    if (error != null) throw error!;
    questions.items.add(ForumQuestionEntity(
      questionId: 'q-${_id++}',
      authorUid: question.authorUid,
      authorName: question.authorName,
      courseTag: question.courseTag,
      topicTag: question.topicTag,
      questionText: question.questionText,
      imageUrl: question.imageUrl,
      isResolved: false,
    ));
    questions.changed();
  }

  @override
  Stream<List<ForumAnswerEntity>> watchForumAnswers(String questionId) =>
      (answers[questionId] ??= LiveList<ForumAnswerEntity>()).watch();

  @override
  Future<void> postForumAnswer(String questionId, ForumAnswerEntity answer) async {
    if (error != null) throw error!;
    final list = answers[questionId] ??= LiveList<ForumAnswerEntity>();
    list.items.add(ForumAnswerEntity(
      answerId: 'a-${_id++}',
      responderName: answer.responderName,
      responderRole: answer.responderRole,
      answerText: answer.answerText,
      isInstructorApproved: false,
    ));
    list.changed();
  }

  @override
  Future<void> markAnswerAsResolved(String questionId, String answerId) async {
    resolved.add((questionId, answerId));
  }
}

// ------------------------------------------------------------- Announcements
class FakeAnnouncementRepository implements AnnouncementRepository {
  final LiveList<AnnouncementEntity> announcements = LiveList<AnnouncementEntity>();
  final List<Map<String, String?>> pushes = [];

  @override
  Stream<List<AnnouncementEntity>> watchAnnouncements() => announcements.watch();

  @override
  Future<void> createAnnouncement(AnnouncementEntity announcement) async {
    announcements.items.add(announcement);
    announcements.changed();
  }

  @override
  Future<void> sendInstantCrisisPush({required String title, required String body, String? targetCourseId}) async {
    pushes.add({'title': title, 'body': body, 'target': targetCourseId});
  }
}
