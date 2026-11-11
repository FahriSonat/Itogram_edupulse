import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/letter_grade.dart';

/// Not girişinde seçilebilen kayıtlı öğrenci.
typedef GradeEntryStudent = ({String uid, String name, String studentNo});

/// Not kaydetme geri çağrısı. Asıl hesaplama ve kayıt UseCase / GradeCalculator
/// katmanındadır; [total] ve [letterGrade] formdaki canlı önizlemenin değeridir.
typedef GradeEntrySaveCallback = Future<void> Function({
  required String studentUid,
  required String studentName,
  required String studentNo,
  required double midterm,
  required double finalScore,
  required double bonus,
  required double total,
  required LetterGrade letterGrade,
});

/// [InstructorGradeEntryModal] eğitmenin sistemdeki kayıtlı öğrenciyi seçip
/// **Vize (%40)**, **Final (%60)** ve **Bonus** girdiği / sildiği form panelidir.
///
/// Kural 4 canlı önizleme: Başarı Notu = (Vize × 0.40) + (Final × 0.60) + Bonus,
/// en fazla 100. Vize ve Final 0-100 arasında doğrulanır.
class InstructorGradeEntryModal extends StatefulWidget {
  const InstructorGradeEntryModal({
    super.key,
    required this.courseName,
    required this.students,
    required this.onSave,
    this.initialStudentUid,
    this.initialMidterm,
    this.initialFinal,
    this.initialBonus,
    this.onDelete,
    this.letterGradeResolver,
  });

  final String courseName;

  /// Derse kayıtlı öğrenciler (seçim listesi).
  final List<GradeEntryStudent> students;
  final GradeEntrySaveCallback onSave;

  /// Düzenleme modunda seçili (ve kilitli) öğrenci.
  final String? initialStudentUid;
  final double? initialMidterm;
  final double? initialFinal;
  final double? initialBonus;
  final VoidCallback? onDelete;

  /// Harf notu eşlemesi; verilmezse [defaultLetterGrade] kullanılır.
  /// (ör. `GradeCalculator.getLetterGrade` buraya bağlanabilir.)
  final LetterGrade Function(double total)? letterGradeResolver;

  static const double midtermWeight = 0.40;
  static const double finalWeight = 0.60;
  static const double maxScore = 100;

  /// Kural 4 önizlemesi: (Vize × 0.40) + (Final × 0.60) + Bonus, 0–100 aralığında.
  static double previewTotal({required double midterm, required double finalExam, double bonus = 0}) {
    final raw = midterm * midtermWeight + finalExam * finalWeight + bonus;
    return raw.clamp(0.0, maxScore).toDouble();
  }

  /// Varsayılan harf notu baremi: AA ≥ 90, BA ≥ 80, BB ≥ 70, aksi halde FF.
  static LetterGrade defaultLetterGrade(double total) {
    if (total >= 90) return LetterGrade.AA;
    if (total >= 80) return LetterGrade.BA;
    if (total >= 70) return LetterGrade.BB;
    return LetterGrade.FF;
  }

  /// 0–100 not doğrulaması. [required] false ise boş bırakılabilir.
  static String? validateScore(String? value, {bool required = true}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? AppStrings.fieldRequired : null;
    final score = double.tryParse(v);
    if (score == null || score < 0 || score > maxScore) return AppStrings.scoreRangeError;
    return null;
  }

  static Future<void> show(
    BuildContext context, {
    required String courseName,
    required List<GradeEntryStudent> students,
    required GradeEntrySaveCallback onSave,
    String? initialStudentUid,
    double? initialMidterm,
    double? initialFinal,
    double? initialBonus,
    VoidCallback? onDelete,
    LetterGrade Function(double total)? letterGradeResolver,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: InstructorGradeEntryModal(
          courseName: courseName,
          students: students,
          onSave: onSave,
          initialStudentUid: initialStudentUid,
          initialMidterm: initialMidterm,
          initialFinal: initialFinal,
          initialBonus: initialBonus,
          onDelete: onDelete,
          letterGradeResolver: letterGradeResolver,
        ),
      ),
    );
  }

  @override
  State<InstructorGradeEntryModal> createState() => _InstructorGradeEntryModalState();
}

class _InstructorGradeEntryModalState extends State<InstructorGradeEntryModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _midtermController = TextEditingController(text: _fmt(widget.initialMidterm));
  late final TextEditingController _finalController = TextEditingController(text: _fmt(widget.initialFinal));
  late final TextEditingController _bonusController = TextEditingController(text: _fmt(widget.initialBonus));
  late String? _studentUid = widget.students.any((s) => s.uid == widget.initialStudentUid)
      ? widget.initialStudentUid
      : null;
  bool _isLoading = false;

  static final List<TextInputFormatter> _scoreFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(3),
  ];

  bool get _isEditing => widget.initialStudentUid != null && _studentUid == widget.initialStudentUid;

  static String _fmt(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : '$v');

  double _value(TextEditingController c) => (double.tryParse(c.text.trim()) ?? 0).clamp(0, 100).toDouble();

  double get _total => InstructorGradeEntryModal.previewTotal(
    midterm: _value(_midtermController),
    finalExam: _value(_finalController),
    bonus: _value(_bonusController),
  );

  LetterGrade get _letter => (widget.letterGradeResolver ?? InstructorGradeEntryModal.defaultLetterGrade).call(_total);

  @override
  void dispose() {
    _midtermController.dispose();
    _finalController.dispose();
    _bonusController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final uid = _studentUid;
    if (!(_formKey.currentState?.validate() ?? false) || uid == null) return;
    final student = widget.students.firstWhere((s) => s.uid == uid);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isLoading = true);
    try {
      await widget.onSave(
        studentUid: student.uid,
        studentName: student.name,
        studentNo: student.studentNo,
        midterm: _value(_midtermController),
        finalScore: _value(_finalController),
        bonus: _value(_bonusController),
        total: _total,
        letterGrade: _letter,
      );
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) messenger?.showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = _total;
    final letter = _letter;
    final letterColor = AppColors.forLetterGrade(letter);
    final rawTotal =
        _value(_midtermController) * InstructorGradeEntryModal.midtermWeight +
        _value(_finalController) * InstructorGradeEntryModal.finalWeight +
        _value(_bonusController);

    return Container(
      padding: AppDimensions.paddingAll24,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: AppDimensions.radiusFull,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.p16),
                Text(
                  _isEditing ? 'Notu Düzenle' : 'Not Girişi',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(widget.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppDimensions.p16),
                DropdownButtonFormField<String>(
                  key: const ValueKey('grade_student_dropdown'),
                  initialValue: _studentUid,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Öğrenci Seçimi',
                    prefixIcon: Icon(Icons.person_search_rounded),
                  ),
                  hint: Text(widget.students.isEmpty ? 'Derse kayıtlı öğrenci yok' : 'Sistemdeki öğrenciyi seçiniz'),
                  validator: (v) => v == null ? AppStrings.studentSelectionRequired : null,
                  items: [
                    for (final s in widget.students)
                      DropdownMenuItem(
                        value: s.uid,
                        child: Text('${s.name} (${s.studentNo})', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  // Düzenlemede öğrenci değiştirilemez (başka öğrencinin notunun üzerine yazılmasın).
                  onChanged: widget.initialStudentUid != null ? null : (v) => setState(() => _studentUid = v),
                ),
                const SizedBox(height: AppDimensions.p12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ScoreField(
                        fieldKey: const ValueKey('midterm_field'),
                        controller: _midtermController,
                        label: 'Vize (%40)',
                        formatters: _scoreFormatters,
                        validator: InstructorGradeEntryModal.validateScore,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p10),
                    Expanded(
                      child: _ScoreField(
                        fieldKey: const ValueKey('final_field'),
                        controller: _finalController,
                        label: 'Final (%60)',
                        formatters: _scoreFormatters,
                        validator: InstructorGradeEntryModal.validateScore,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p10),
                    Expanded(
                      child: _ScoreField(
                        fieldKey: const ValueKey('bonus_field'),
                        controller: _bonusController,
                        label: 'Bonus',
                        formatters: _scoreFormatters,
                        validator: (v) => InstructorGradeEntryModal.validateScore(v, required: false),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p16),
                // Canlı sonuç kartı
                Container(
                  padding: AppDimensions.paddingAll16,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: AppDimensions.radius16,
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hesaplanan Başarı Notu (Max 100)',
                              maxLines: 2,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              total.toStringAsFixed(1),
                              key: const ValueKey('grade_total_preview'),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            if (rawTotal > InstructorGradeEntryModal.maxScore)
                              const Text(
                                'Bonus ile 100 aşıldı → 100\'e sabitlendi',
                                style: TextStyle(fontSize: 10, color: AppColors.lateSubmissionOrange),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.p8),
                      // Rozet kesilmeden, gerekirse küçülerek sığar (büyük yazı ölçeği).
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: letterColor.withValues(alpha: 0.2),
                              borderRadius: AppDimensions.radius12,
                              border: Border.all(color: letterColor, width: 1.5),
                            ),
                            child: Text(
                              'Harf Notu: ${letter.name}',
                              key: const ValueKey('grade_letter_preview'),
                              style: TextStyle(color: letterColor, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.p8),
                Text(AppStrings.formulaExplanation, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                const SizedBox(height: AppDimensions.p16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading || widget.students.isEmpty ? null : _handleSave,
                        child: Text(_isLoading ? 'Kaydediliyor...' : 'Notu Sisteme İşle'),
                      ),
                    ),
                    if (widget.onDelete != null) ...[
                      const SizedBox(width: AppDimensions.p12),
                      IconButton.outlined(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.criticalAbsenceRed),
                        onPressed: _isLoading ? null : widget.onDelete,
                        tooltip: 'Notu Sil',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.formatters,
    required this.validator,
    required this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final List<TextInputFormatter> formatters;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: formatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, hintText: '0-100', errorMaxLines: 3),
    );
  }
}
