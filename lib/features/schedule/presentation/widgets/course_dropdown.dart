import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/course_schedule_entity.dart';

/// Eğitmen ekranlarında (yoklama, devamsızlık, ödev, not) ortak ders seçici.
class CourseDropdown extends StatelessWidget {
  const CourseDropdown({
    super.key,
    required this.courses,
    required this.selectedCourseId,
    required this.onChanged,
    this.label = 'Ders',
  });

  final List<CourseScheduleEntity> courses;
  final String? selectedCourseId;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final hasSelection = courses.any((c) => c.courseId == selectedCourseId);
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>('course_dropdown_$selectedCourseId'),
      initialValue: hasSelection ? selectedCourseId : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.menu_book_rounded),
        contentPadding: AppDimensions.paddingH16V8,
      ),
      items: [
        for (final c in courses)
          DropdownMenuItem<String>(
            value: c.courseId,
            child: Text('${c.courseCode} · ${c.courseName}', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) {
        if (id != null) onChanged(id);
      },
    );
  }
}
