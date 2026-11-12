import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/letter_grade.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../../../../core/widgets/role_visibility_guard.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../schedule/presentation/widgets/course_dropdown.dart';
import '../../domain/entities/course_grade_entity.dart';
import '../cubit/grades_cubit.dart';
import '../cubit/grades_state.dart';
import '../widgets/course_grade_detail_card.dart';
import '../widgets/gpa_simulator_dashboard.dart';
import '../widgets/instructor_grade_entry_modal.dart';

/// 2.5 NOT BİLGİSİ VE AKADEMİK BAŞARI EKRANI (Grade Info Page).
/// 
/// Kural 4: Dinamik Ağırlıklı Not Hesaplama & Harf Skalası:
/// - Başarı Notu = Vize × 0.40 + Final × 0.60 + Bonus (Maksimum 100 puan).
/// - Öğrenci Görünümü: 4.00'lük kümülatif GPA göstergesi, "Bu dersten şu harfi alırsam
///   ortalamam ne olur?" interaktif GPA Simülatörü ve ders bazlı detay kartları.
/// - Eğitmen Görünümü: Dersi ve sisteme kayıtlı öğrencileri seçerek Vize, Final, Bonus
///   notu girme ([InstructorGradeEntryModal]), düzenleme ve silme panelleri.
class GradeInfoPage extends StatelessWidget {
  const GradeInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.currentRole;
    final uid = context.currentUser?.uid ?? '';

    // Kullanıcı rolüne göre öğrenci veya eğitmen not verilerini yükleyen Cubit
    return BlocProvider<GradesCubit>(
      create: (_) {
        final cubit = GetIt.instance<GradesCubit>();
        return role.isInstructor ? (cubit..loadForInstructor()) : (cubit..loadForStudent(uid));
      },
      // Rol koruması ile öğrenci ve eğitmen arayüzlerini ayırır
      child: RoleVisibilityGuard(
        currentRole: role,
        studentBuilder: (_) => const _StudentGradesView(),
        instructorBuilder: (_) => const _InstructorGradesView(),
      ),
    );
  }
}

/// Null sayısal değerler için sıfır döndüren yardımcı dönüştürücü.
double _num(double? v) => v ?? 0;

/// Dersin resmi harf notunu çözer; yoksa ortalamaya göre hesaplar.
LetterGrade _letterOf(CourseGradeEntity g) =>
    g.letterGrade ?? GradeCalculator.getLetterGrade(_num(g.totalAverage));

// =========================================================================
// Öğrenci Görünümü
// =========================================================================

/// Öğrencinin genel not ortalamasını gördüğü ve simüle ettiği arayüz.
class _StudentGradesView extends StatelessWidget {
  const _StudentGradesView();

  @override
  Widget build(BuildContext context) {
    final uid = context.currentUser?.uid ?? '';

    return BlocBuilder<GradesCubit, GradesState>(
      builder: (context, state) {
        final cubit = context.read<GradesCubit>();

        // Yüklenme ve hata durumları
        if (state.status.isLoading) return const LoadingStateView(message: 'Notlar yükleniyor...');
        if (state.status == ViewStatus.failure) {
          return ErrorStateView(message: state.errorMessage, onRetry: () => cubit.loadForStudent(uid));
        }

        // Henüz not girilmemişse boş durum görünümü
        if (state.grades.isEmpty) {
          return const EmptyStateView(
            title: 'Henüz not girilmedi',
            message: 'Eğitmenin not girdiğinde burada görünecek.',
            icon: Icons.school_outlined,
          );
        }

        return ListView(
          padding: AppDimensions.paddingAll16,
          children: [
            // 4.00 üzerinden Kümülatif GPA ve Simülatör Dashboard Paneli
            GpaSimulatorDashboard(
              cumulativeGpa: state.gpa,
              termGpa: state.simulatedGpa,
              totalCredits: state.totalCredits,
              onSimulateGpa: () => _openSimulator(context),
            ),

            // Simülasyon aktifse simüle edilen değer ve sıfırlama butonu
            if (state.isSimulating) ...[
              const SizedBox(height: AppDimensions.p8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Simülasyon: ${state.simulatedGpa.toStringAsFixed(2)} (gerçek: ${state.gpa.toStringAsFixed(2)})',
                      key: const Key('gpa_simulation_label'),
                    ),
                  ),
                  TextButton(onPressed: cubit.resetSimulation, child: const Text('Sıfırla')),
                ],
              ),
            ],

            const SectionHeader(title: 'Ders Notlarım', padding: EdgeInsets.symmetric(vertical: 8)),

            // Her ders için Vize, Final, Bonus ve Harf Notu Detay Kartı
            for (final g in state.grades) ...[
              CourseGradeDetailCard(
                courseCode: state.courseCodeFor(g.courseId),
                courseName: g.courseName,
                credit: g.credit,
                midtermScore: _num(g.midtermScore),
                finalExamScore: _num(g.finalScore),
                bonusScore: _num(g.bonusScore),
                totalAverage: _num(g.totalAverage),
                letterGrade: _letterOf(g),
              ),
              const SizedBox(height: AppDimensions.p12),
            ],
          ],
        );
      },
    );
  }

  /// Öğrencinin ders harf notlarını değiştirerek GPA senaryolarını test ettiği alt modal.
  static Future<void> _openSimulator(BuildContext context) {
    final cubit = context.read<GradesCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider<GradesCubit>.value(
        value: cubit,
        child: BlocBuilder<GradesCubit, GradesState>(
          builder: (context, state) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: AppDimensions.paddingAll16,
              children: [
                Text('GPA Simülatörü', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppDimensions.p4),
                Text('Simüle GPA: ${state.simulatedGpa.toStringAsFixed(2)} / 4.00',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppDimensions.p12),
                // Derslerin harf notlarını geçici olarak seçip simüle etme listesi
                for (final g in state.grades)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(g.courseName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${g.credit} kredi'),
                    trailing: DropdownButton<LetterGrade>(
                      value: state.overrides[g.courseId] ?? _letterOf(g),
                      onChanged: (l) {
                        if (l != null) cubit.simulate(g.courseId, l);
                      },
                      items: [
                        for (final l in LetterGrade.values.where((l) => l != LetterGrade.NA))
                          DropdownMenuItem(value: l, child: Text(l.name)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Eğitmen Görünümü
// =========================================================================

/// Eğitmenin ders seçip öğrencilere not atadığı, düzenlediği veya sildiği arayüz.
class _InstructorGradesView extends StatelessWidget {
  const _InstructorGradesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Seçili ders varsa "Not Gir" yüzen butonunu göster
      floatingActionButton: BlocBuilder<GradesCubit, GradesState>(
        buildWhen: (p, c) => p.selectedCourseId != c.selectedCourseId,
        builder: (context, state) => state.selectedCourse == null
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                key: const Key('grades_add'),
                onPressed: () => _openEntry(context),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Not Gir'),
              ),
      ),
      body: BlocConsumer<GradesCubit, GradesState>(
        listenWhen: (p, c) => c.actionMessage != null && p.actionMessage != c.actionMessage,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.actionMessage!))),
        builder: (context, state) {
          final cubit = context.read<GradesCubit>();

          if (state.status == ViewStatus.failure) {
            return ErrorStateView(message: state.errorMessage, onRetry: cubit.loadForInstructor);
          }
          if (state.courses.isEmpty) {
            return state.status.isLoading
                ? const LoadingStateView(message: 'Dersler yükleniyor...')
                : const EmptyStateView(title: 'Ders bulunamadı', message: 'Önce Ders Programı\'na ders ekleyin.');
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p16, AppDimensions.p16, 96),
            children: [
              // Not girişi yapılacak dersin seçimi
              CourseDropdown(courses: state.courses, selectedCourseId: state.selectedCourseId, onChanged: cubit.selectCourse),
              const SizedBox(height: AppDimensions.p8),

              // Kural 4 Formül Bilgilendirme Metni
              Text(
                'Başarı Notu = Vize × 0.40 + Final × 0.60 + Bonus (en fazla 100)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppDimensions.p12),

              // Yüklenme, boş veya not listesi
              if (state.status.isLoading)
                const Padding(padding: AppDimensions.paddingAll24, child: Center(child: CircularProgressIndicator()))
              else if (state.grades.isEmpty)
                const EmptyStateView(
                  title: 'Bu derste not yok',
                  message: '"Not Gir" ile sistemdeki öğrencilerden seçerek not atayabilirsin.',
                  icon: Icons.grading_rounded,
                )
              else
                for (final g in state.grades) ...[
                  Text(
                    '${g.studentName} · ${g.studentNo}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppDimensions.p4),
                  // Eğitmen için düzenleme ve silme aksiyonları içeren not kartı
                  CourseGradeDetailCard(
                    key: ValueKey<String>('grade_${g.gradeId}'),
                    courseCode: state.courseCodeFor(g.courseId),
                    courseName: g.courseName,
                    credit: g.credit,
                    midtermScore: _num(g.midtermScore),
                    finalExamScore: _num(g.finalScore),
                    bonusScore: _num(g.bonusScore),
                    totalAverage: _num(g.totalAverage),
                    letterGrade: _letterOf(g),
                    isInstructor: true,
                    onEdit: () => _openEntry(context, existing: g),
                    onDelete: () => _confirmDelete(context, g),
                  ),
                  const SizedBox(height: AppDimensions.p12),
                ],
            ],
          );
        },
      ),
    );
  }

  /// Öğrenci seçip Vize / Final / Bonus notlarını girmeye yarayan modal formunu açar.
  static Future<void> _openEntry(BuildContext context, {CourseGradeEntity? existing}) {
    final cubit = context.read<GradesCubit>();
    final course = cubit.state.selectedCourse;
    if (course == null) return Future.value();
    final students = cubit.state.students;

    return InstructorGradeEntryModal.show(
      context,
      courseName: course.courseName,
      students: [
        for (final s in students) (uid: s.uid, name: s.name, studentNo: s.studentNo),
      ],
      initialStudentUid: existing?.studentUid,
      initialMidterm: existing?.midtermScore,
      initialFinal: existing?.finalScore,
      initialBonus: existing?.bonusScore,
      onDelete: existing == null ? null : () => cubit.deleteGrade(existing),
      letterGradeResolver: GradeCalculator.getLetterGrade,
      onSave: ({
        required String studentUid,
        required String studentName,
        required String studentNo,
        required double midterm,
        required double finalScore,
        required double bonus,
        required double total,
        required LetterGrade letterGrade,
      }) async {
        await cubit.saveGrade(
          student: (uid: studentUid, name: studentName, studentNo: studentNo),
          midterm: midterm,
          finalScore: finalScore,
          bonus: bonus,
        );
      },
    );
  }

  /// Öğrenci notunu silmeden önce onay isteyen diyalog penceresi.
  static Future<void> _confirmDelete(BuildContext context, CourseGradeEntity grade) async {
    final cubit = context.read<GradesCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notu sil'),
        content: Text('${grade.studentName} için ${grade.courseName} notu silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok ?? false) await cubit.deleteGrade(grade);
  }
}
