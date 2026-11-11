// Geçici Geliştirici 2 UI Önizleme Girişi (git'e eklenmez).
// Çalıştırmak için: flutter run -d windows -t tool/dev2_ui_preview.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itogram_edupulse/core/constants/app_dimensions.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/announcement_type.dart';
import 'package:itogram_edupulse/core/enums/attendance_status.dart';
import 'package:itogram_edupulse/core/enums/letter_grade.dart';
import 'package:itogram_edupulse/core/enums/submission_status.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/services/local_storage_service.dart';
import 'package:itogram_edupulse/core/theme/app_scroll_behavior.dart';
import 'package:itogram_edupulse/core/theme/app_theme.dart';
import 'package:itogram_edupulse/core/theme/theme_cubit.dart';
import 'package:itogram_edupulse/core/widgets/dashboard/instructor_dashboard_hero.dart';
import 'package:itogram_edupulse/core/widgets/dashboard/student_dashboard_hero.dart';
import 'package:itogram_edupulse/core/widgets/main_scaffold_shell.dart';
import 'package:itogram_edupulse/core/widgets/role_visibility_guard.dart';
import 'package:itogram_edupulse/core/widgets/section_header.dart';
import 'package:itogram_edupulse/core/widgets/state_views/empty_state_view.dart';
import 'package:itogram_edupulse/core/widgets/state_views/error_state_view.dart';
import 'package:itogram_edupulse/core/widgets/state_views/loading_state_view.dart';
import 'package:itogram_edupulse/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:itogram_edupulse/features/announcements/presentation/widgets/crisis_broadcast_bottom_sheet.dart';
import 'package:itogram_edupulse/features/announcements/presentation/widgets/interactive_event_calendar.dart';
import 'package:itogram_edupulse/features/assignments/presentation/widgets/assignment_countdown_card.dart';
import 'package:itogram_edupulse/features/assignments/presentation/widgets/audio_written_feedback_box.dart';
import 'package:itogram_edupulse/features/assignments/presentation/widgets/late_submission_warning_banner.dart';
import 'package:itogram_edupulse/features/assignments/presentation/widgets/storage_upload_progress_bar.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/bell_curve_chart_painter.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/critical_absence_red_list.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/dynamic_qr_pin_board.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/live_attendance_roster_tabs.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/student_absence_progress_card.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/student_qr_pin_scanner.dart';
import 'package:itogram_edupulse/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:itogram_edupulse/features/auth/presentation/widgets/onboarding_illustrations.dart';
import 'package:itogram_edupulse/features/auth/presentation/widgets/role_selection_toggle.dart';
import 'package:itogram_edupulse/features/forum/presentation/widgets/ask_question_modal.dart';
import 'package:itogram_edupulse/features/forum/presentation/widgets/forum_question_card.dart';
import 'package:itogram_edupulse/features/forum/presentation/widgets/instructor_resolved_answer_card.dart';
import 'package:itogram_edupulse/features/grades/presentation/widgets/course_grade_detail_card.dart';
import 'package:itogram_edupulse/features/grades/presentation/widgets/gpa_simulator_dashboard.dart';
import 'package:itogram_edupulse/features/grades/presentation/widgets/instructor_grade_entry_modal.dart';
import 'package:itogram_edupulse/features/schedule/presentation/widgets/course_schedule_card.dart';
import 'package:itogram_edupulse/features/schedule/presentation/widgets/course_visuals.dart';
import 'package:itogram_edupulse/features/schedule/presentation/widgets/day_selector_tabs.dart';
import 'package:itogram_edupulse/features/schedule/presentation/widgets/instructor_course_editor_modal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Dev2PreviewApp());
}

class _Dev2PreviewApp extends StatefulWidget {
  const _Dev2PreviewApp();

  @override
  State<_Dev2PreviewApp> createState() => _Dev2PreviewAppState();
}

class _Dev2PreviewAppState extends State<_Dev2PreviewApp> {
  late final ThemeCubit _themeCubit = ThemeCubit(LocalStorageService());

  @override
  void dispose() {
    _themeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>.value(
      value: _themeCubit,
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return MaterialApp(
            title: 'EduPulse — Geliştirici 2 UI Önizleme',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            home: const _PreviewHome(),
          );
        },
      ),
    );
  }
}

class _PreviewHome extends StatefulWidget {
  const _PreviewHome();

  @override
  State<_PreviewHome> createState() => _PreviewHomeState();
}

class _PreviewHomeState extends State<_PreviewHome> {
  UserRole _role = UserRole.student;
  String _route = '/home';
  int _selectedDay = 1;
  DateTime _selectedDate = DateTime.now();

  int get _tabIndex {
    final idx = MainScaffoldShell.indexForRoute(_route);
    return idx < 0 ? 0 : idx;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isInstructor = _role == UserRole.instructor;

    return MainScaffoldShell(
      title: MainScaffoldShell.titleForRoute(_route),
      currentRoute: _route,
      currentIndex: _tabIndex,
      userRole: _role,
      userName: isInstructor ? 'Mustafa Hoca' : 'Ayberk Erdem',
      userEmailOrNo: isInstructor ? 'mustafa@softito.edu.tr' : '2026101042',
      unreadNotifications: 3,
      onNotificationPressed: () => _snack('3 okunmamış bildirim (önizleme)'),
      onNavigationIndexChanged: (i) => setState(() => _route = MainScaffoldShell.tabRoutes[i]),
      onDrawerNavigate: (r) => setState(() => _route = r),
      onLogout: () => _snack('Çıkış aksiyonu (önizleme)'),
      appBarActions: [
        IconButton(
          tooltip: 'Rol Değiştir (Öğrenci / Eğitmen)',
          icon: Icon(isInstructor ? Icons.school_outlined : Icons.admin_panel_settings_outlined),
          onPressed: () {
            setState(() {
              _role = isInstructor ? UserRole.student : UserRole.instructor;
            });
          },
        ),
        IconButton(
          tooltip: 'Tema Değiştir',
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
          onPressed: () => context.read<ThemeCubit>().toggleTheme(),
        ),
      ],
      floatingActionButton: RoleVisibilityGuard.onlyInstructor(
        currentRole: _role,
        child: FloatingActionButton.extended(
          onPressed: () => CrisisBroadcastBottomSheet.show(
            context,
            targets: const {'all_campus': 'Tüm Kampüs', 'mob101': 'MOB101 • Flutter'},
            onBroadcast: ({
              required targetId,
              required targetLabel,
              required title,
              required message,
            }) async => _snack('Kriz yayını önizlemesi: $title → $targetLabel'),
          ),
          icon: const Icon(Icons.campaign_rounded),
          label: const Text('Kriz Yayını'),
        ),
      ),
      child: _buildBody(context, isInstructor),
    );
  }

  Widget _buildBody(BuildContext context, bool isInstructor) {
    return switch (_route) {
      '/home' => _buildHomeTab(isInstructor),
      '/schedule' => _buildScheduleTab(isInstructor),
      '/live-attendance' => _buildAttendanceTab(isInstructor),
      '/absence-control' => _buildAbsenceTab(isInstructor),
      '/assignments' => _buildAssignmentsTab(isInstructor),
      '/grades' => _buildGradesTab(isInstructor),
      '/forum' => _buildForumTab(isInstructor),
      _ => _buildHomeTab(isInstructor),
    };
  }

  Widget _buildHomeTab(bool isInstructor) {
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        if (isInstructor)
          InstructorDashboardHero(
            onStartAttendance: () => setState(() => _route = '/live-attendance'),
            onPendingHomeworksTap: () => setState(() => _route = '/assignments'),
            onClassAnalysisTap: () => setState(() => _route = '/absence-control'),
            onSendAnnouncementTap: () => CrisisBroadcastBottomSheet.show(
              context,
              targets: const {'all_campus': 'Tüm Kampüs', 'mob101': 'MOB101 • Flutter'},
              onBroadcast: ({
                required targetId,
                required targetLabel,
                required title,
                required message,
              }) async => _snack('Kriz yayını: $title'),
            ),
            onQuestionsTap: () => setState(() => _route = '/forum'),
          )
        else
          StudentDashboardHero(
            nextCourseStartTime: now.add(const Duration(minutes: 42)),
            onNextCourseTap: () => setState(() => _route = '/schedule'),
            onAttendanceTap: () => setState(() => _route = '/absence-control'),
            onAssignmentsTap: () => setState(() => _route = '/assignments'),
            onGpaTap: () => setState(() => _route = '/grades'),
            onBannerTap: () => _snack('Haftalık başarı özeti'),
          ),
        const SizedBox(height: AppDimensions.p16),
        InteractiveEventCalendar(
          selectedDate: _selectedDate,
          eventDates: {now, now.add(const Duration(days: 2)), now.add(const Duration(days: 5))},
          onDateSelected: (d) => setState(() => _selectedDate = d),
        ),
        const SizedBox(height: AppDimensions.p8),
        const SectionHeader(title: 'Kampüs Duyuruları'),
        AnnouncementCard(
          title: 'Flutter Demo Day Hazırlık Semineri',
          content: '13 Kasım Cuma günü canlı jüri sunumu öncesi teknik prova yapılacaktır.',
          type: AnnouncementType.event,
          eventDate: now.add(const Duration(days: 2)),
          authorName: 'Mustafa Hoca',
          targetLabel: 'Tüm Kampüs',
          onAddToCalendar: () => _snack('Takvime eklendi (önizleme)'),
        ),
        AnnouncementCard(
          title: 'Acil Derslik Değişikliği',
          content: 'MOB101 dersi bugün geçici olarak D-107 amfisine alınmıştır.',
          type: AnnouncementType.urgent,
          eventDate: now,
          authorName: 'Akademi Yönetimi',
          targetLabel: 'MOB101',
        ),
        const SectionHeader(title: 'Giriş & Durum Bileşenleri Önizleme'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
          child: Column(
            children: [
              const SizedBox(height: 170, child: DualPortalIllustration()),
              const SizedBox(height: AppDimensions.p12),
              RoleSelectionToggle(
                selectedRole: _role,
                onRoleChanged: (r) => setState(() => _role = r),
              ),
              const SizedBox(height: AppDimensions.p12),
              const AuthTextField(
                label: AppStrings.studentNoLabel,
                hint: '2026101042',
                prefixIcon: Icons.badge_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab(bool isInstructor) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        DaySelectorTabs(
          selectedDayIndex: _selectedDay,
          includeWeekend: true,
          onDaySelected: (d) => setState(() => _selectedDay = d),
        ),
        CourseScheduleCard(
          courseCode: 'MOB101',
          courseName: 'Flutter ile Mobil Geliştirme',
          instructorName: 'Mustafa Hoca',
          roomLocation: 'D-107',
          startTime: '10:30',
          endTime: '12:00',
          icon: CourseVisuals.iconFor('MOB101'),
          iconBgColor: CourseVisuals.colorFor('MOB101'),
          isHighlighted: true,
          nextClassTime: DateTime.now().add(const Duration(minutes: 35)),
          isInstructor: isInstructor,
          onEdit: () => InstructorCourseEditorModal.show(
            context,
            initialCourseId: 'mob101',
            initialCourseCode: 'MOB101',
            initialCourseName: 'Flutter ile Mobil Geliştirme',
            initialInstructorName: 'Mustafa Hoca',
            initialRoom: 'D-107',
            initialDayOfWeek: _selectedDay,
            initialStartTime: '10:30',
            initialEndTime: '12:00',
            onSave: ({
              courseId,
              required courseCode,
              required courseName,
              required instructorName,
              required roomLocation,
              required dayOfWeek,
              required startTime,
              required endTime,
            }) async => _snack('Ders güncellendi: $courseCode ($roomLocation)'),
          ),
          onDelete: () => _snack('Sil butonu (önizleme)'),
        ),
        CourseScheduleCard(
          courseCode: 'CS204',
          courseName: 'Yazılım Mimarisi & Clean Code',
          instructorName: 'Dr. Ayşe Kaya',
          roomLocation: 'A-204',
          startTime: '14:00',
          endTime: '16:00',
          icon: CourseVisuals.iconFor('CS204'),
          iconBgColor: CourseVisuals.colorFor('CS204'),
          isInstructor: isInstructor,
        ),
      ],
    );
  }

  Widget _buildAttendanceTab(bool isInstructor) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        if (isInstructor) ...[
          DynamicQrPinBoard(
            pinCode: '4829',
            qrToken: 'edupulse:mob101:4829',
            courseLabel: 'MOB101 • Flutter',
            expiresAt: DateTime.now().add(const Duration(seconds: 55)),
            onExpireOrRefresh: () => _snack('60 sn doldu, yeni QR/PIN tetikleniyor'),
          ),
          LiveAttendanceRosterTabs(
            attendees: [
              AttendeeItem(
                studentUid: '1',
                studentName: 'Ayberk Erdem',
                studentNo: '2026101042',
                status: AttendanceStatus.present,
                recordedAt: DateTime.now(),
              ),
              const AttendeeItem(
                studentUid: '2',
                studentName: 'Merve Kedersiz',
                studentNo: '2026101018',
                status: AttendanceStatus.late,
              ),
              const AttendeeItem(
                studentUid: '3',
                studentName: 'Ahmet Eroğlu',
                studentNo: '2026101055',
                status: AttendanceStatus.absent,
              ),
            ],
            onStatusChanged: (item, status) =>
                _snack('${item.studentName} → ${AppStrings.attendanceStatus(status)}'),
          ),
        ] else
          StudentQrPinScanner(
            onSubmitPin: (pin) async => _snack('PIN doğrulandı: $pin'),
            onOpenQrScanner: () => _snack('Kamera QR tarayıcısı tetiklendi'),
          ),
      ],
    );
  }

  Widget _buildAbsenceTab(bool isInstructor) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        if (isInstructor) ...[
          BellCurveChartWidget.fromScores(
            midtermScores: const [52, 64, 70, 78, 84, 88, 92, 61, 74, 81],
            finalScores: const [58, 68, 75, 82, 90, 94, 86, 65, 79, 88],
          ),
          CriticalAbsenceRedList(
            atRiskStudents: [
              CriticalAbsenceItem(
                studentUid: '3',
                studentName: 'Ahmet Eroğlu',
                studentNo: '2026101055',
                courseName: 'MOB101 • Flutter',
                absentHours: 9,
                totalCourseHours: 40,
              ),
              CriticalAbsenceItem(
                studentUid: '4',
                studentName: 'Fahri Sonat',
                studentNo: '2026101031',
                courseName: 'CS204 • Mimari',
                absentHours: 7,
                totalCourseHours: 40,
              ),
            ],
            onSendPushWarning: (s) => _snack('Push uyarısı: ${s.studentName}'),
          ),
        ] else ...[
          const StudentAbsenceProgressCard(
            courseName: 'MOB101 • Flutter ile Mobil Geliştirme',
            totalCourseHours: 40,
            absentHours: 3,
          ),
          const StudentAbsenceProgressCard(
            courseName: 'CS204 • Yazılım Mimarisi',
            totalCourseHours: 40,
            absentHours: 9,
          ),
        ],
      ],
    );
  }

  Widget _buildAssignmentsTab(bool isInstructor) {
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        const LateSubmissionWarningBanner(),
        AssignmentCountdownCard(
          title: 'Clean Architecture UI Tasarım Sistemi',
          courseName: 'MOB101',
          description: 'Material 3 tema ve ortak widget katmanının hazırlanması.',
          dueDate: now.add(const Duration(days: 2, hours: 5)),
          status: SubmissionStatus.pending,
          onSubmitPressed: () => _snack('Dosya yükleme başlatıldı (önizleme)'),
        ),
        AssignmentCountdownCard(
          title: 'State Management Cubit Akışları',
          courseName: 'CS204',
          description: 'BLoC/Cubit birim testleri ile teslim.',
          dueDate: now.subtract(const Duration(hours: 6)),
          status: SubmissionStatus.late,
          onSubmitPressed: () => _snack('Gecikmeli teslim (-10 ceza)'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.p16),
          child: StorageUploadProgressBar(
            progress: 0.72,
            fileName: 'edupulse_ui_kit_v2.pdf',
            fileSize: '4.8 MB',
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.p16),
          child: AudioWrittenFeedbackBox(
            isInstructor: isInstructor,
            writtenFeedback: 'Material 3 renk hiyerarşisi ve kart boşlukları çok temiz.',
            audioFeedbackUrl: 'https://example.com/feedback.m4a',
            audioDurationLabel: '0:42',
            onPlayAudio: () => _snack('Sesli not oynatılıyor (önizleme)'),
            onStartRecording: () => _snack('Kayıt başlatıldı'),
          ),
        ),
      ],
    );
  }

  Widget _buildGradesTab(bool isInstructor) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        GpaSimulatorDashboard(
          cumulativeGpa: 3.48,
          termGpa: 3.62,
          totalCredits: 24,
          onSimulateGpa: () => InstructorGradeEntryModal.show(
            context,
            courseName: 'MOB101 • Flutter ile Mobil Geliştirme',
            students: const [
              (uid: '1', name: 'Ayberk Erdem', studentNo: '2026101042'),
              (uid: '2', name: 'Merve Kedersiz', studentNo: '2026101018'),
            ],
            initialStudentUid: '1',
            initialMidterm: 85,
            initialFinal: 92,
            initialBonus: 5,
            onSave: ({
              required studentUid,
              required studentName,
              required studentNo,
              required midterm,
              required finalScore,
              required bonus,
              required total,
              required letterGrade,
            }) async => _snack('$studentName: ${total.toStringAsFixed(1)} (${letterGrade.name})'),
          ),
        ),
        CourseGradeDetailCard(
          courseCode: 'MOB101',
          courseName: 'Flutter ile Mobil Geliştirme',
          credit: 6,
          midtermScore: 88,
          finalExamScore: 94,
          bonusScore: 5,
          totalAverage: 96.6,
          letterGrade: LetterGrade.AA,
          isInstructor: isInstructor,
          onEdit: () => _snack('Not düzenle (önizleme)'),
        ),
        CourseGradeDetailCard(
          courseCode: 'CS204',
          courseName: 'Yazılım Mimarisi',
          credit: 5,
          midtermScore: 76,
          finalExamScore: 82,
          totalAverage: 79.6,
          letterGrade: LetterGrade.BA,
          isInstructor: isInstructor,
        ),
      ],
    );
  }

  Widget _buildForumTab(bool isInstructor) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.p32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p8, AppDimensions.p16, 0),
          child: OutlinedButton.icon(
            onPressed: () => AskQuestionModal.show(
              context,
              courseTags: const ['MOB101', 'CS204', 'CLD301'],
              topicSuggestions: const ['Material 3', 'CustomPainter', 'GoRouter'],
              onAskQuestion: ({
                required courseTag,
                required topicTag,
                required questionText,
                localPhotoPath,
              }) async => _snack('Soru gönderildi: $courseTag #$topicTag'),
            ),
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Soru Sor Modalını Aç'),
          ),
        ),
        ForumQuestionCard(
          authorName: 'Ayberk Erdem',
          courseTag: 'MOB101',
          topicTag: 'CustomPainter',
          questionText: 'Çan eğrisi grafiğinde küçük ekranlarda eksen etiketlerinin taşmaması için ne önerirsiniz?',
          createdAt: DateTime.now(),
          isResolved: true,
          answerCount: 2,
          onTap: () => _snack('Soru detayına gidildi (önizleme)'),
        ),
        InstructorResolvedAnswerCard(
          responderName: 'Mustafa Hoca',
          responderRole: UserRole.instructor,
          answerText: 'TextPainter genişliğini `0..width - painter.width` arasında clamp etmek her ekranda taşmayı önler.',
          answeredAt: DateTime.now(),
          isInstructorApproved: true,
        ),
        const SectionHeader(title: '4 Durum Kalkanı Örnekleri'),
        const SizedBox(height: 180, child: LoadingStateView(skeletonItemCount: 2)),
        ErrorStateView(onRetry: () => _snack('Tekrar dene tetiklendi')),
        EmptyStateView(actionLabel: 'Yeni Ekle', onAction: () => _snack('Boş durum aksiyonu')),
      ],
    );
  }
}
