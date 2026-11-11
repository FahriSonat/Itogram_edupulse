// Geliştirici 6 — Sıfır RenderFlex overflow kuralı: 13 sayfanın tamamı her iki
// rolde, dar ekran (320x640) ve büyük yazı (1.3x) ile hatasız çizilmelidir.
// Taşma olursa Flutter test çerçevesi bunu hata olarak yakalar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/announcement_type.dart';
import 'package:itogram_edupulse/core/enums/letter_grade.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/announcements/domain/entities/announcement_entity.dart';
import 'package:itogram_edupulse/features/announcements/presentation/pages/home_announcements_page.dart';
import 'package:itogram_edupulse/features/assignments/domain/entities/assignment_entity.dart';
import 'package:itogram_edupulse/features/assignments/presentation/pages/assignment_control_page.dart';
import 'package:itogram_edupulse/features/assignments/presentation/pages/submission_grading_detail_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/absence_control_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/live_attendance_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/login_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/register_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/splash_page.dart';
import 'package:itogram_edupulse/features/forum/domain/entities/forum_answer_entity.dart';
import 'package:itogram_edupulse/features/forum/domain/entities/forum_question_entity.dart';
import 'package:itogram_edupulse/features/forum/presentation/pages/forum_page.dart';
import 'package:itogram_edupulse/features/forum/presentation/pages/forum_question_detail_page.dart';
import 'package:itogram_edupulse/features/grades/domain/entities/course_grade_entity.dart';
import 'package:itogram_edupulse/features/grades/presentation/pages/grade_info_page.dart';
import 'package:itogram_edupulse/features/schedule/presentation/pages/weekly_schedule_page.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/page_harness.dart';

/// Her sayfayı dolu verilerle göstermek için örnek veri.
void _seed(TestBackend b) {
  const longName = 'Meltem Jülide Taşkıran Uzun Soyadı';
  b.announcements.announcements.items.add(AnnouncementEntity(
    id: '1',
    title: 'Kampüs Genelinde Büyük Flutter Hackathonu ve Ödül Töreni',
    content: 'Uzun açıklama ' * 10,
    type: AnnouncementType.event,
    eventDate: DateTime.now(),
    authorName: longName,
  ));
  b.attendance.studentRecords['c-mob/uid-student'] = absenceRecord(courseId: 'c-mob', uid: 'uid-student', absent: 10);
  b.attendance.classRecords.items.add(absenceRecord(courseId: 'c-mob', uid: 'a', absent: 12, name: longName));
  b.assignments.assignments.items.add(AssignmentEntity(
    assignmentId: 'hw-1',
    courseId: 'c-mob',
    courseName: 'Mobil Programlama',
    title: 'Çok Uzun Bir Ödev Başlığı: Clean Architecture ile Uçtan Uca Uygulama',
    description: 'Açıklama ' * 8,
    rubricCriteria: 'Mimari %40',
    dueDate: DateTime.now().add(const Duration(days: 3)),
  ));
  b.assignments.submissions.items.add(submissionOf(assignmentId: 'hw-1', late: true, name: longName));
  b.grades.grades.items.add(const CourseGradeEntity(
    gradeId: 'uid-student',
    courseId: 'c-mob',
    courseName: 'Mobil Programlama',
    credit: 3,
    studentUid: 'uid-student',
    studentName: longName,
    studentNo: '20261234',
    midtermScore: 70,
    finalScore: 85,
    bonusScore: 5,
    totalAverage: 84,
    letterGrade: LetterGrade.BA,
  ));
  b.forum.questions.items.add(const ForumQuestionEntity(
    questionId: 'q-1',
    authorUid: 'uid-student',
    authorName: longName,
    courseTag: 'MOB101',
    topicTag: 'Cubit ve Stream Yönetimi',
    questionText: 'Çok uzun bir soru metni, birden fazla satıra yayılan açıklama ile birlikte geliyor.',
    isResolved: false,
  ));
  b.forum.answers['q-1'] = LiveList<ForumAnswerEntity>([
    ForumAnswerEntity(
      answerId: 'a-1',
      responderName: 'Fahri Faruk Sonat',
      responderRole: 'instructor',
      answerText: 'Uzun yanıt metni ' * 6,
      isInstructorApproved: true,
    ),
  ]);
}

void main() {
  final pages = <String, Widget Function()>{
    'Splash': () => const SplashPage(),
    'Login': () => const LoginPage(),
    'Register': () => const RegisterPage(),
    'ForgotPassword': () => const ForgotPasswordPage(),
    'HomeAnnouncements': () => const HomeAnnouncementsPage(),
    'WeeklySchedule': () => const WeeklySchedulePage(),
    'LiveAttendance': () => const LiveAttendancePage(),
    'AbsenceControl': () => const AbsenceControlPage(),
    'AssignmentControl': () => const AssignmentControlPage(),
    'SubmissionGradingDetail': () => const SubmissionGradingDetailPage(submissionId: 'uid-student', assignmentId: 'hw-1'),
    'GradeInfo': () => const GradeInfoPage(),
    'Forum': () => const ForumPage(),
    'ForumQuestionDetail': () => const ForumQuestionDetailPage(questionId: 'q-1'),
  };

  for (final role in [UserRole.student, UserRole.instructor]) {
    for (final entry in pages.entries) {
      testWidgets('${entry.key} (${role.name}) dar ekran + büyük yazıda taşmaz', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final original = FlutterError.onError;
        FlutterError.onError = errors.add;
        try {
          final backend = TestBackend();
          await backend.register();
          _seed(backend);
          await pumpPage(
            tester,
            entry.value(),
            backend: backend,
            role: role,
            size: const Size(320, 640),
            textScale: 1.3,
          );
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await settle(tester);
        } finally {
          FlutterError.onError = original;
        }
        // Hata varsa taşan widget'ın dosya:satır bilgisini rapora ekle.
        final report = errors.map((d) {
          final lines = d.toString().split('\n');
          return lines.where((l) => l.contains('overflowed') || l.contains('file:///')).take(3).join(' | ');
        }).join('\n');
        expect(errors, isEmpty, reason: report);
      });
    }
  }
}
