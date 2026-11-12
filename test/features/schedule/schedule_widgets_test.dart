import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/widgets/countdown_timer_widget.dart';
import 'package:itogram_edupulse/features/schedule/presentation/widgets/course_schedule_card.dart';
import 'package:itogram_edupulse/features/schedule/presentation/widgets/day_selector_tabs.dart';
import 'package:itogram_edupulse/features/schedule/presentation/widgets/instructor_course_editor_modal.dart';

import '../../helpers/design_test_harness.dart';

void main() {
  group('CourseScheduleCard', () {
    testWidgets('amfi (D-107), hoca adı ve geri sayım sayacını gösterir', (tester) async {
      await pumpDesign(
        tester,
        CourseScheduleCard(
          courseCode: 'MOB101',
          courseName: 'Flutter ile Mobil',
          instructorName: 'Mustafa Hoca',
          roomLocation: 'D-107',
          startTime: '10:30',
          endTime: '12:00',
          nextClassTime: DateTime.now().add(const Duration(hours: 2)),
        ),
      );
      expect(find.text('D-107'), findsOneWidget);
      expect(find.text('Mustafa Hoca'), findsOneWidget);
      expect(find.text('10:30 - 12:00'), findsOneWidget);
      expect(find.byType(CountdownTimerWidget), findsOneWidget);
      expect(find.byTooltip('Düzenle'), findsNothing, reason: 'Öğrenci düzenleyemez');
    });

    testWidgets('eğitmen kartında Düzenle / Sil ikonları çalışır', (tester) async {
      var edited = false;
      var deleted = false;
      await pumpDesign(
        tester,
        CourseScheduleCard(
          courseCode: 'MOB101',
          courseName: 'Flutter',
          instructorName: 'Hoca',
          roomLocation: 'A204',
          startTime: '09:00',
          endTime: '10:00',
          isInstructor: true,
          onEdit: () => edited = true,
          onDelete: () => deleted = true,
        ),
      );
      await tester.tap(find.byTooltip('Düzenle'));
      await tester.tap(find.byTooltip('Sil'));
      expect(edited && deleted, isTrue);
    });
  });

  testWidgets('DaySelectorTabs gün seçimini 1..7 olarak bildirir', (tester) async {
    int? selected;
    await pumpDesign(tester, DaySelectorTabs(selectedDayIndex: 1, onDaySelected: (d) => selected = d));
    expect(find.text('Cum'), findsOneWidget);
    expect(find.text('Cmt'), findsNothing);
    await tester.tap(find.text('Çar'));
    expect(selected, 3);
  });

  group('InstructorCourseEditorModal', () {
    test('saat doğrulaması SS:DD biçimi', () {
      expect(InstructorCourseEditorModal.validateTime('09:30'), isNull);
      expect(InstructorCourseEditorModal.validateTime('23:59'), isNull);
      expect(InstructorCourseEditorModal.validateTime('24:00'), AppStrings.timeFormatError);
      expect(InstructorCourseEditorModal.validateTime('9:30'), AppStrings.timeFormatError);
      expect(InstructorCourseEditorModal.validateTime(''), AppStrings.fieldRequired);
    });

    Future<void> fill(WidgetTester tester, {required String start, required String end}) async {
      await tester.enterText(find.byKey(const ValueKey('course_code_field')), 'mob101');
      await tester.enterText(find.byKey(const ValueKey('course_name_field')), 'Flutter ile Mobil');
      await tester.enterText(find.byKey(const ValueKey('instructor_name_field')), 'Mustafa Hoca');
      await tester.enterText(find.byKey(const ValueKey('room_field')), 'd-107');
      await tester.enterText(find.byKey(const ValueKey('start_time_field')), start);
      await tester.enterText(find.byKey(const ValueKey('end_time_field')), end);
      await tester.ensureVisible(find.text('Ders Programını Kaydet'));
      await tester.tap(find.text('Ders Programını Kaydet'));
      await tester.pump();
    }

    testWidgets('bitiş saati başlangıçtan önceyse kaydetmez', (tester) async {
      var saved = false;
      await pumpDesign(
        tester,
        InstructorCourseEditorModal(
          onSave: ({
            courseId,
            required courseCode,
            required courseName,
            required instructorName,
            required roomLocation,
            required dayOfWeek,
            required startTime,
            required endTime,
          }) async => saved = true,
        ),
        scrollable: false,
      );
      await fill(tester, start: '12:00', end: '10:30');
      expect(saved, isFalse);
      expect(find.text(AppStrings.endTimeBeforeStart), findsOneWidget);
    });

    testWidgets('geçerli form kod ve amfiyi büyük harfe çevirip kaydeder', (tester) async {
      Map<String, Object?>? saved;
      await pumpDesign(
        tester,
        InstructorCourseEditorModal(
          initialDayOfWeek: 3,
          onSave:
              ({
                courseId,
                required courseCode,
                required courseName,
                required instructorName,
                required roomLocation,
                required dayOfWeek,
                required startTime,
                required endTime,
              }) async {
                saved = {
                  'id': courseId,
                  'code': courseCode,
                  'room': roomLocation,
                  'day': dayOfWeek,
                  'start': startTime,
                  'end': endTime,
                  'instructor': instructorName,
                };
              },
        ),
        scrollable: false,
      );
      expect(find.text('Yeni Ders Ekle'), findsOneWidget);
      await fill(tester, start: '10:30', end: '12:00');
      expect(saved, {
        'id': null,
        'code': 'MOB101',
        'room': 'D-107',
        'day': 3,
        'start': '10:30',
        'end': '12:00',
        'instructor': 'Mustafa Hoca',
      });
    });

    testWidgets('yeni ders formunda sahte varsayılan değer yoktur', (tester) async {
      await pumpDesign(
        tester,
        InstructorCourseEditorModal(
          onSave: ({
            courseId,
            required courseCode,
            required courseName,
            required instructorName,
            required roomLocation,
            required dayOfWeek,
            required startTime,
            required endTime,
          }) async {},
        ),
        scrollable: false,
      );
      final instructorField = tester.widget<EditableText>(
        find.descendant(of: find.byKey(const ValueKey('instructor_name_field')), matching: find.byType(EditableText)),
      );
      expect(instructorField.controller.text, isEmpty);
    });
  });

  testWidgets('ders programı bileşenleri hiçbir ekran koşulunda taşmaz', (tester) async {
    await expectNoLayoutErrors(
      tester,
      () => CourseScheduleCard(
        courseCode: 'MOB101',
        courseName: 'İleri Seviye Mobil Uygulama Geliştirme ve Yazılım Mimarisi',
        instructorName: 'Prof. Dr. Çok Uzun İsimli Eğitmen Adı Soyadı',
        roomLocation: 'Mühendislik Fakültesi D-107',
        startTime: '10:30',
        endTime: '12:00',
        isInstructor: true,
        nextClassTime: DateTime.now().add(const Duration(days: 2)),
        onEdit: () {},
        onDelete: () {},
      ),
    );
    await expectNoLayoutErrors(
      tester,
      () => DaySelectorTabs(selectedDayIndex: 2, includeWeekend: true, onDaySelected: (_) {}),
    );
    await expectNoLayoutErrors(
      tester,
      () => InstructorCourseEditorModal(
        initialCourseId: 'c1',
        initialCourseCode: 'MOB101',
        initialCourseName: 'Flutter',
        initialInstructorName: 'Hoca',
        initialRoom: 'D-107',
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
        }) async {},
      ),
      scrollable: false,
    );
  });
}

