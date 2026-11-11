import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/letter_grade.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../../../../core/widgets/dashboard/portal_avatar.dart';
import '../../../../core/widgets/edu_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../attendance/presentation/cubit/absence_control_cubit.dart';
import '../../../attendance/presentation/widgets/bell_curve_chart_painter.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../../schedule/presentation/cubit/schedule_cubit.dart';
import '../../domain/entities/course_grade_entity.dart';
import '../../domain/usecases/calculate_gpa_simulation_usecase.dart';
import '../cubit/grades_cubit.dart';
import '../cubit/grades_state.dart';
import '../widgets/course_grade_detail_card.dart';
import '../widgets/gpa_simulator_dashboard.dart';
import '../widgets/instructor_grade_entry_modal.dart';

/// [GradeInfoPage] Modül 1.4 / 2.4:
/// - Öğrenci: profil, GPA paneli + simülatör, ders bazlı çan eğrisi ve not kartları.
/// - Eğitmen: ders seçimi, sınıf istatistikleri, çan eğrisi ve not girişi.
class GradeInfoPage extends StatelessWidget {
  const GradeInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    return BlocBuilder<GradesCubit, GradesState>(
      builder: (context, state) {
        switch (state.status) {
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const LoadingStateView();
          case ViewStatus.failure:
            return ErrorStateView(message: state.errorMessage, onRetry: context.read<GradesCubit>().start);
          case ViewStatus.loaded:
            return user.isStudent ? _StudentGrades(user: user, state: state) : _InstructorGrades(state: state);
        }
      },
    );
  }
}

// -----------------------------------------------------------------------------
// ÖĞRENCİ
// -----------------------------------------------------------------------------

class _StudentGrades extends StatefulWidget {
  const _StudentGrades({required this.user, required this.state});

  final UserEntity user;
  final GradesState state;

  @override
  State<_StudentGrades> createState() => _StudentGradesState();
}

class _StudentGradesState extends State<_StudentGrades> {
  String? _curveCourse;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final state = widget.state;
    final grades = state.gradesFor(user.uid);
    final current = grades.where((g) => g.isCurrentTerm).toList();
    final previous = grades.where((g) => !g.isCurrentTerm).toList();
    final gpa = state.gpaFor(user.uid);
    final absence = context.watch<AbsenceControlCubit>().state;
    final critical = absence.criticalFor(user.uid);

    final selectedCode = _curveCourse ?? (current.isNotEmpty ? current.first.courseCode : null);
    final selected = current.where((g) => g.courseCode == selectedCode).firstOrNull;
    final stats = selectedCode == null ? null : state.statsFor(selectedCode);

    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.p8, bottom: AppDimensions.p32),
      children: [
        _ProfileCard(user: user),
        GpaSimulatorDashboard(
          cumulativeGpa: gpa.cumulativeGpa,
          termGpa: gpa.termGpa,
          totalCredits: gpa.totalCredits,
          onSimulateGpa: () => _GpaSimulatorSheet.show(context, user: user, grades: grades),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
          child: EduCard(
            onTap: () => Navigator.of(context).pushNamed(RouteNames.absenceControl),
            glowColor: critical.isEmpty ? AppColors.secondaryLight : AppColors.criticalAbsenceRed,
            child: Row(
              children: [
                Icon(
                  critical.isEmpty ? Icons.verified_outlined : Icons.warning_amber_rounded,
                  color: critical.isEmpty ? AppColors.secondaryLight : AppColors.criticalAbsenceRed,
                ),
                const SizedBox(width: AppDimensions.p12),
                Expanded(
                  child: Text(
                    critical.isEmpty
                        ? '${AppStrings.absenceSummaryTitle}: genel katılım %${absence.attendanceRateFor(user.uid).round()}'
                        : '${critical.length} derste ${AppStrings.criticalRiskBadge}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        if (current.isNotEmpty && stats != null) ...[
          _CourseChips(
            codes: [for (final g in current) g.courseCode],
            selected: selectedCode!,
            onSelected: (c) => setState(() => _curveCourse = c),
          ),
          BellCurveChartWidget.fromScores(
            midtermScores: [for (final g in state.courseGrades(selectedCode)) g.midterm],
            finalScores: [for (final g in state.courseGrades(selectedCode)) g.finalExam],
            studentMidterm: selected?.midterm,
            studentFinal: selected?.finalExam,
            title: '${selected?.courseName ?? selectedCode} • Vize-Final Çan Eğrisi',
          ),
        ],
        SectionHeader(title: '${CourseGradeEntity.currentTerm} Notları'),
        if (current.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.p20, vertical: AppDimensions.p8),
            child: Text('Bu dönem için henüz not girilmedi.'),
          ),
        for (final g in current) _gradeCard(g),
        if (previous.isNotEmpty) ...[
          const SectionHeader(title: 'Önceki Dönemler'),
          for (final g in previous) _gradeCard(g),
        ],
      ],
    );
  }

  Widget _gradeCard(CourseGradeEntity g) => CourseGradeDetailCard(
    courseCode: g.courseCode,
    courseName: g.term == CourseGradeEntity.currentTerm ? g.courseName : '${g.courseName} • ${g.term}',
    credit: g.credit,
    midtermScore: g.midterm,
    finalExamScore: g.finalExam,
    bonusScore: g.bonus,
    totalAverage: g.total,
    letterGrade: g.letterGrade,
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return EduCard(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      child: Row(
        children: [
          PortalAvatar(role: user.role, size: 64),
          const SizedBox(width: AppDimensions.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${user.role.displayName} • ${user.schoolNo}', style: TextStyle(color: muted, fontSize: 13)),
                Text(
                  user.email,
                  style: TextStyle(color: muted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.department.isNotEmpty)
                  Text(
                    user.department,
                    style: TextStyle(color: muted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseChips extends StatelessWidget {
  const _CourseChips({required this.codes, required this.selected, required this.onSelected});

  final List<String> codes;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: 6),
      children: [
        for (final c in codes) ...[
          ChoiceChip(label: Text(c), selected: c == selected, onSelected: (_) => onSelected(c)),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

/// "Bu dersten şu notu alırsam GPA'm ne olur?" simülatörü.
class _GpaSimulatorSheet extends StatefulWidget {
  const _GpaSimulatorSheet({required this.grades, required this.ungradedCourses});

  final List<CourseGradeEntity> grades;
  final List<CourseScheduleEntity> ungradedCourses;

  static Future<void> show(BuildContext context, {required UserEntity user, required List<CourseGradeEntity> grades}) {
    final gradedCodes = grades.where((g) => g.isCurrentTerm).map((g) => g.courseCode).toSet();
    final ungraded = context
        .read<ScheduleCubit>()
        .state
        .uniqueCourses
        .where((c) => !gradedCodes.contains(c.courseCode))
        .toList();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GpaSimulatorSheet(grades: grades, ungradedCourses: ungraded),
    );
  }

  @override
  State<_GpaSimulatorSheet> createState() => _GpaSimulatorSheetState();
}

class _GpaSimulatorSheetState extends State<_GpaSimulatorSheet> {
  final Map<String, LetterGrade> _overrides = {};
  final Map<String, LetterGrade?> _extra = {};
  static const _gpa = CalculateGpaSimulationUseCase();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = widget.grades.where((g) => g.isCurrentTerm).toList();
    final extra = <CreditGrade>[
      for (final c in widget.ungradedCourses)
        if (_extra[c.courseCode] != null) (credit: c.credit, grade: _extra[c.courseCode]!),
    ];
    final real = _gpa(widget.grades);
    final sim = _gpa(widget.grades, overrides: _overrides, extraCourses: extra);

    Widget row(
      String code,
      String name,
      int credit,
      LetterGrade? value,
      ValueChanged<LetterGrade?> onChanged, {
      bool allowEmpty = false,
    }) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('$code • $name', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$credit kredi'),
        trailing: DropdownButton<LetterGrade?>(
          value: value,
          hint: const Text('Not yok'),
          items: [
            if (allowEmpty) const DropdownMenuItem<LetterGrade?>(value: null, child: Text('Not yok')),
            for (final l in LetterGrade.values)
              DropdownMenuItem<LetterGrade?>(
                value: l,
                child: Text('${l.name} (${l.coefficient.toStringAsFixed(1)})', style: TextStyle(color: l.color)),
              ),
          ],
          onChanged: onChanged,
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      padding: AppDimensions.paddingAll24,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GPA Simülatörü', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Bu dönemki derslerin için olası harf notlarını seç; GPA anında hesaplanır.'),
            const SizedBox(height: AppDimensions.p16),
            Row(
              children: [
                Expanded(
                  child: _GpaTile(label: 'Dönem GPA', real: real.termGpa, simulated: sim.termGpa),
                ),
                const SizedBox(width: AppDimensions.p12),
                Expanded(
                  child: _GpaTile(label: 'Genel GPA', real: real.cumulativeGpa, simulated: sim.cumulativeGpa),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.p12),
            for (final g in current)
              row(
                g.courseCode,
                g.courseName,
                g.credit,
                _overrides[g.courseCode] ?? g.letterGrade,
                (v) => setState(() => v == null ? _overrides.remove(g.courseCode) : _overrides[g.courseCode] = v),
              ),
            for (final c in widget.ungradedCourses)
              row(
                c.courseCode,
                c.courseName,
                c.credit,
                _extra[c.courseCode],
                (v) => setState(() => _extra[c.courseCode] = v),
                allowEmpty: true,
              ),
            const SizedBox(height: AppDimensions.p12),
            OutlinedButton(
              onPressed: () => setState(() {
                _overrides.clear();
                _extra.clear();
              }),
              child: const Text('Sıfırla'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpaTile extends StatelessWidget {
  const _GpaTile({required this.label, required this.real, required this.simulated});

  final String label;
  final double real;
  final double simulated;

  @override
  Widget build(BuildContext context) {
    final diff = simulated - real;
    final color = diff > 0.001
        ? AppColors.resolvedGreen
        : (diff < -0.001 ? AppColors.criticalAbsenceRed : AppColors.textSecondaryLight);
    return EduCard(
      padding: AppDimensions.paddingAll12,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(simulated.toStringAsFixed(2), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(
            diff.abs() < 0.001 ? 'mevcut' : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EĞİTMEN
// -----------------------------------------------------------------------------

class _InstructorGrades extends StatefulWidget {
  const _InstructorGrades({required this.state});

  final GradesState state;

  @override
  State<_InstructorGrades> createState() => _InstructorGradesState();
}

class _InstructorGradesState extends State<_InstructorGrades> {
  late final Future<List<UserEntity>> _students = context.read<GradesCubit>().loadStudents();
  String? _courseCode;

  Future<void> _openEntry(
    BuildContext context,
    CourseScheduleEntity course, {
    UserEntity? student,
    CourseGradeEntity? existing,
  }) async {
    final cubit = context.read<GradesCubit>();
    final actor = context.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    final students = await _students;
    if (!context.mounted) return;
    return InstructorGradeEntryModal.show(
      context,
      courseName: '${course.courseCode} • ${course.courseName}',
      students: [for (final s in students) (uid: s.uid, name: s.fullName, studentNo: s.schoolNo)],
      initialStudentUid: student?.uid,
      initialMidterm: existing?.midterm,
      initialFinal: existing?.finalExam,
      initialBonus: existing?.bonus,
      onDelete: existing == null
          ? null
          : () async {
              Navigator.of(context).pop();
              await _delete(context, existing);
            },
      onSave:
          ({
            required studentUid,
            required studentName,
            required studentNo,
            required midterm,
            required finalScore,
            required bonus,
            required total,
            required letterGrade,
          }) async {
            final target = students.firstWhere((s) => s.uid == studentUid);
            await cubit.saveGrade(
              actor: actor,
              student: target,
              courseCode: course.courseCode,
              courseName: course.courseName,
              credit: course.credit,
              courseId: course.id,
              midterm: midterm,
              finalExam: finalScore,
              bonus: bonus,
            );
            messenger.showSnackBar(SnackBar(content: Text('${target.fullName} için not kaydedildi.')));
          },
    );
  }

  Future<void> _delete(BuildContext context, CourseGradeEntity grade) async {
    final cubit = context.read<GradesCubit>();
    final actor = context.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notu sil'),
        content: Text('${grade.studentName} — ${grade.courseCode} notu silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await cubit.deleteGrade(actor: actor, gradeId: grade.id);
      messenger.showSnackBar(const SnackBar(content: Text('Not silindi.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(Failure.from(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<ScheduleCubit>().state.uniqueCourses;
    if (courses.isEmpty) {
      return const Center(child: Text('Not girmek için önce ders programına ders ekleyin.'));
    }
    final course = courses.firstWhere((c) => c.courseCode == _courseCode, orElse: () => courses.first);
    final stats = widget.state.statsFor(course.courseCode);
    final courseGrades = {for (final g in widget.state.courseGrades(course.courseCode)) g.studentUid: g};

    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.p8, bottom: 96),
      children: [
        _CourseChips(
          codes: [for (final c in courses) c.courseCode],
          selected: course.courseCode,
          onSelected: (c) => setState(() => _courseCode = c),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p4),
          child: Row(
            children: [
              Expanded(
                child: _StatTile(label: 'Ortalama', value: stats.count == 0 ? '-' : stats.mean.toStringAsFixed(1)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Std. Sapma',
                  value: stats.count == 0 ? '-' : stats.standardDeviation.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(label: 'Geçme', value: stats.count == 0 ? '-' : '%${stats.passRate.round()}'),
              ),
            ],
          ),
        ),
        if (stats.count > 0)
          BellCurveChartWidget.fromScores(
            midtermScores: [for (final g in courseGrades.values) g.midterm],
            finalScores: [for (final g in courseGrades.values) g.finalExam],
            title: '${course.courseName} • Vize-Final Çan Eğrisi',
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
          child: Text(AppStrings.formulaExplanation, style: Theme.of(context).textTheme.bodySmall),
        ),
        SectionHeader(title: 'Öğrenci Notları', actionLabel: 'Not Gir', onAction: () => _openEntry(context, course)),
        FutureBuilder<List<UserEntity>>(
          future: _students,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: AppDimensions.paddingAll24,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final students = snapshot.data!;
            return Column(
              children: [
                for (final s in students)
                  if (courseGrades[s.uid] case final g?)
                    CourseGradeDetailCard(
                      courseCode: s.schoolNo,
                      courseName: s.fullName,
                      credit: g.credit,
                      midtermScore: g.midterm,
                      finalExamScore: g.finalExam,
                      bonusScore: g.bonus,
                      totalAverage: g.total,
                      letterGrade: g.letterGrade,
                      isInstructor: true,
                      onEdit: () => _openEntry(context, course, student: s, existing: g),
                      onDelete: () => _delete(context, g),
                    )
                  else
                    EduCard(
                      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
                      child: Row(
                        children: [
                          const Icon(Icons.pending_outlined, color: AppColors.warningAmber),
                          const SizedBox(width: AppDimensions.p12),
                          Expanded(child: Text('${s.fullName} • ${s.schoolNo}\nNot girilmedi')),
                          TextButton(
                            onPressed: () => _openEntry(context, course, student: s),
                            child: const Text('Not Gir'),
                          ),
                        ],
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => EduCard(
    padding: AppDimensions.paddingAll12,
    child: Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}
