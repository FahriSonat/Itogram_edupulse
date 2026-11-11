import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

/// Yeni ödev yayınlama geri çağrısı — alanlar `AssignmentEntity` ile aynıdır.
typedef CreateAssignmentCallback = Future<void> Function({
  required String courseId,
  required String courseName,
  required String title,
  required String description,
  required String rubricCriteria,
  required DateTime dueDate,
});

/// [CreateAssignmentSheet] eğitmenin **"Yeni Ödev & Rubrik Aç"** formudur.
///
/// Ders seçimi, ödev başlığı, yönerge, puanlama rubriği ve son teslim tarihi
/// (tarih + saat) alınır. Rubrik için hazır kriter çipleri sunulur.
class CreateAssignmentSheet extends StatefulWidget {
  const CreateAssignmentSheet({super.key, required this.courses, required this.onCreate, this.initialDueDate});

  /// Ders kimliği → ders adı. İlk eleman varsayılan seçimdir.
  final Map<String, String> courses;
  final CreateAssignmentCallback onCreate;

  /// Varsayılan son teslim tarihi (verilmezse 7 gün sonra 23:59).
  final DateTime? initialDueDate;

  /// Hazır rubrik kriterleri (dokununca rubrik alanına eklenir).
  static const List<String> rubricSuggestions = [
    'Kod Kalitesi (%40)',
    'UI/UX Tasarım (%30)',
    'Dokümantasyon (%30)',
    'Test Kapsamı (%20)',
    'Zamanında Teslim (%10)',
  ];

  static Future<void> show(
    BuildContext context, {
    required Map<String, String> courses,
    required CreateAssignmentCallback onCreate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: CreateAssignmentSheet(courses: courses, onCreate: onCreate),
      ),
    );
  }

  @override
  State<CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<CreateAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _rubricController = TextEditingController();
  late String? _selectedCourseId = widget.courses.isEmpty ? null : widget.courses.keys.first;
  late DateTime _dueDate = widget.initialDueDate ?? _defaultDueDate();
  bool _isLoading = false;

  static DateTime _defaultDueDate() {
    final inAWeek = DateTime.now().add(const Duration(days: 7));
    return DateTime(inAWeek.year, inAWeek.month, inAWeek.day, 23, 59);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _rubricController.dispose();
    super.dispose();
  }

  void _addRubric(String criterion) {
    final current = _rubricController.text.trim();
    if (current.contains(criterion)) return;
    _rubricController.text = current.isEmpty ? criterion : '$current, $criterion';
    setState(() {});
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(now) ? now : _dueDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dueDate));
    if (!mounted) return;
    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _dueDate.hour,
        pickedTime?.minute ?? _dueDate.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    final courseId = _selectedCourseId;
    if (courseId == null || !(_formKey.currentState?.validate() ?? false)) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isLoading = true);
    try {
      await widget.onCreate(
        courseId: courseId,
        courseName: widget.courses[courseId] ?? courseId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        rubricCriteria: _rubricController.text.trim(),
        dueDate: _dueDate,
      );
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) messenger?.showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _formatDue(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} - ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

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
                  'Yeni Ödev & Rubrik Oluştur',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppDimensions.p16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourseId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Ders Seçimi'),
                  validator: (v) => v == null ? 'Ders seçiniz' : null,
                  items: [
                    for (final c in widget.courses.entries)
                      DropdownMenuItem(
                        value: c.key,
                        child: Text(c.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (val) => setState(() => _selectedCourseId = val),
                ),
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  key: const ValueKey('assignment_title_field'),
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık zorunludur' : null,
                  decoration: const InputDecoration(labelText: 'Ödev Başlığı', hintText: 'Clean Architecture Projesi'),
                ),
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  key: const ValueKey('assignment_description_field'),
                  controller: _descController,
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Yönerge zorunludur' : null,
                  decoration: const InputDecoration(
                    labelText: 'Ödev Yönergesi',
                    hintText: 'Gereksinimler ve teslim formatı...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  key: const ValueKey('assignment_rubric_field'),
                  controller: _rubricController,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'En az bir rubrik kriteri giriniz' : null,
                  decoration: const InputDecoration(
                    labelText: 'Değerlendirme Rubriği',
                    hintText: 'Örn: Kod Kalitesi (%40), UI/UX Tasarım (%30)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppDimensions.p8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final r in CreateAssignmentSheet.rubricSuggestions)
                      ActionChip(
                        label: Text(r, style: const TextStyle(fontSize: 11)),
                        avatar: const Icon(Icons.add_rounded, size: 14),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _addRubric(r),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p12, vertical: AppDimensions.p8),
                  decoration: BoxDecoration(
                    borderRadius: AppDimensions.radius12,
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available_rounded, color: primary, size: 20),
                      const SizedBox(width: AppDimensions.p8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Son Teslim Tarihi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatDue(_dueDate),
                              style: TextStyle(color: primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickDueDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: const Text('Değiştir'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.p8),
                Text(AppStrings.lateSubmissionWarning, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                const SizedBox(height: AppDimensions.p16),
                ElevatedButton(
                  onPressed: _isLoading || _selectedCourseId == null ? null : _handleSubmit,
                  child: Text(_isLoading ? 'Yayınlanıyor...' : 'Ödevi Öğrencilere Yayınla'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
