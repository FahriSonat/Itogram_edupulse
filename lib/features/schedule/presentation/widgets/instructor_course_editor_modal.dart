import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

/// Ders kaydetme geri çağrısı — alanlar `CourseScheduleEntity` ile birebir aynıdır.
typedef CourseEditorSaveCallback = Future<void> Function({
  String? courseId,
  required String courseCode,
  required String courseName,
  required String instructorName,
  required String roomLocation,
  required int dayOfWeek,
  required String startTime,
  required String endTime,
});

/// [InstructorCourseEditorModal] eğitmenin ders programına ders eklediği veya mevcut
/// dersin kodunu, adını, hocasını, amfisini (ör. `D-107`), gününü ve saatini
/// değiştirdiği modal formdur. Saatler `SS:DD` biçiminde doğrulanır; bitiş saati
/// başlangıçtan sonra olmalıdır.
class InstructorCourseEditorModal extends StatefulWidget {
  const InstructorCourseEditorModal({
    super.key,
    this.initialCourseId,
    this.initialCourseCode,
    this.initialCourseName,
    this.initialInstructorName,
    this.initialRoom,
    this.initialDayOfWeek = 1,
    this.initialStartTime,
    this.initialEndTime,
    required this.onSave,
  });

  final String? initialCourseId;
  final String? initialCourseCode;
  final String? initialCourseName;
  final String? initialInstructorName;
  final String? initialRoom;
  final int initialDayOfWeek;
  final String? initialStartTime;
  final String? initialEndTime;
  final CourseEditorSaveCallback onSave;

  static const List<String> dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  static final RegExp _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// `SS:DD` biçimini doğrular.
  static String? validateTime(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return AppStrings.fieldRequired;
    if (!_timePattern.hasMatch(v)) return AppStrings.timeFormatError;
    return null;
  }

  static int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static Future<void> show(
    BuildContext context, {
    String? initialCourseId,
    String? initialCourseCode,
    String? initialCourseName,
    String? initialInstructorName,
    String? initialRoom,
    int initialDayOfWeek = 1,
    String? initialStartTime,
    String? initialEndTime,
    required CourseEditorSaveCallback onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: InstructorCourseEditorModal(
          initialCourseId: initialCourseId,
          initialCourseCode: initialCourseCode,
          initialCourseName: initialCourseName,
          initialInstructorName: initialInstructorName,
          initialRoom: initialRoom,
          initialDayOfWeek: initialDayOfWeek,
          initialStartTime: initialStartTime,
          initialEndTime: initialEndTime,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<InstructorCourseEditorModal> createState() => _InstructorCourseEditorModalState();
}

class _InstructorCourseEditorModalState extends State<InstructorCourseEditorModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController = TextEditingController(text: widget.initialCourseCode);
  late final TextEditingController _nameController = TextEditingController(text: widget.initialCourseName);
  late final TextEditingController _instructorController = TextEditingController(text: widget.initialInstructorName);
  late final TextEditingController _roomController = TextEditingController(text: widget.initialRoom);
  late final TextEditingController _startTimeController = TextEditingController(text: widget.initialStartTime);
  late final TextEditingController _endTimeController = TextEditingController(text: widget.initialEndTime);
  late int _selectedDay = widget.initialDayOfWeek.clamp(1, 7);
  bool _isLoading = false;

  static final List<TextInputFormatter> _timeFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
    LengthLimitingTextInputFormatter(5),
  ];

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _instructorController.dispose();
    _roomController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final current = controller.text.trim();
    final initial = InstructorCourseEditorModal.validateTime(current) == null
        ? TimeOfDay(hour: int.parse(current.substring(0, 2)), minute: int.parse(current.substring(3)))
        : const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null || !mounted) return;
    controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  String? _validateEndTime(String? value) {
    final base = InstructorCourseEditorModal.validateTime(value);
    if (base != null) return base;
    final start = _startTimeController.text.trim();
    if (InstructorCourseEditorModal.validateTime(start) != null) return null;
    final isAfter = InstructorCourseEditorModal._minutes(value!.trim()) > InstructorCourseEditorModal._minutes(start);
    return isAfter ? null : AppStrings.endTimeBeforeStart;
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isLoading = true);
    try {
      await widget.onSave(
        courseId: widget.initialCourseId,
        courseCode: _codeController.text.trim().toUpperCase(),
        courseName: _nameController.text.trim(),
        instructorName: _instructorController.text.trim(),
        roomLocation: _roomController.text.trim().toUpperCase(),
        dayOfWeek: _selectedDay,
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
      );
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) messenger?.showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? AppStrings.fieldRequired : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialCourseId != null;

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
                  isEditing ? 'Ders Bilgilerini Düzenle' : 'Yeni Ders Ekle',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppDimensions.p16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: const ValueKey('course_code_field'),
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                        decoration: const InputDecoration(labelText: 'Ders Kodu', hintText: 'MOB101'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p12),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        key: const ValueKey('course_name_field'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ders adı zorunludur' : null,
                        decoration: const InputDecoration(labelText: 'Ders Adı', hintText: 'Flutter ile Mobil'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  key: const ValueKey('instructor_name_field'),
                  controller: _instructorController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Hocanın adı-soyadı gerekli' : null,
                  decoration: const InputDecoration(
                    labelText: 'Dersin Hocası (Ad Soyad)',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: AppDimensions.p12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('room_field'),
                        controller: _roomController,
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Amfi / sınıf gerekli' : null,
                        decoration: const InputDecoration(
                          labelText: 'Sınıf / Amfi',
                          hintText: 'D-107',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedDay,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Ders Günü'),
                        items: [
                          for (var i = 0; i < InstructorCourseEditorModal.dayNames.length; i++)
                            DropdownMenuItem(
                              value: i + 1,
                              child: Text(InstructorCourseEditorModal.dayNames[i], overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedDay = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TimeField(
                        fieldKey: const ValueKey('start_time_field'),
                        controller: _startTimeController,
                        label: 'Başlangıç',
                        formatters: _timeFormatters,
                        validator: InstructorCourseEditorModal.validateTime,
                        onPick: () => _pickTime(_startTimeController),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p12),
                    Expanded(
                      child: _TimeField(
                        fieldKey: const ValueKey('end_time_field'),
                        controller: _endTimeController,
                        label: 'Bitiş',
                        formatters: _timeFormatters,
                        validator: _validateEndTime,
                        onPick: () => _pickTime(_endTimeController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: Text(_isLoading ? 'Kaydediliyor...' : 'Ders Programını Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.formatters,
    required this.validator,
    required this.onPick,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final List<TextInputFormatter> formatters;
  final FormFieldValidator<String> validator;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.datetime,
      inputFormatters: formatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: '09:30',
        errorMaxLines: 3,
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time_rounded, size: 20),
          tooltip: '$label saatini seç',
          onPressed: onPick,
        ),
      ),
    );
  }
}
