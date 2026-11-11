// Geliştirici 5 & 6 — 2.1 Ders Programı: ScheduleCubit + WeeklySchedulePage.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/enums/view_status.dart';
import 'package:itogram_edupulse/features/schedule/domain/usecases/add_or_remove_course_usecase.dart';
import 'package:itogram_edupulse/features/schedule/domain/usecases/update_course_details_usecase.dart';
import 'package:itogram_edupulse/features/schedule/domain/usecases/watch_weekly_schedule_usecase.dart';
import 'package:itogram_edupulse/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:itogram_edupulse/features/schedule/presentation/pages/weekly_schedule_page.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/page_harness.dart';

void main() {
  group('ScheduleCubit', () {
    late FakeScheduleRepository repo;
    late ScheduleCubit cubit;
    // 9 Kasım 2026 Pazartesi 09:00
    final monday9 = DateTime(2026, 11, 9, 9);

    setUp(() {
      repo = FakeScheduleRepository();
      cubit = ScheduleCubit(
        watchWeeklyScheduleUseCase: WatchWeeklyScheduleUseCase(repo),
        addOrRemoveCourseUseCase: AddOrRemoveCourseUseCase(repo),
        updateCourseDetailsUseCase: UpdateCourseDetailsUseCase(repo),
        clock: () => monday9,
      );
    });
    tearDown(() => cubit.close());

    Future<void> flush() => Future<void>.delayed(Duration.zero);

    test('açılış günü bugündür ve dersler gün bazında gruplanır', () async {
      cubit.start();
      await flush();
      expect(cubit.state.status, ViewStatus.loaded);
      expect(cubit.state.selectedDay, DateTime.monday);
      expect(cubit.state.coursesOfSelectedDay.map((c) => c.courseCode), ['MOB101']);

      cubit.selectDay(DateTime.wednesday);
      expect(cubit.state.coursesOfSelectedDay.map((c) => c.courseCode), ['ALG201']);
    });

    test('sıradaki ders ve derse kalan süre doğru hesaplanır', () async {
      cubit.start();
      await flush();
      expect(cubit.nextCourse?.courseCode, 'MOB101');
      expect(cubit.nextStartOf(mobileCourse), DateTime(2026, 11, 9, 10, 30));
      expect(cubit.nextStartOf(algoCourse), DateTime(2026, 11, 11, 13));
    });

    test('eğitmen ders ekler, amfiyi günceller ve siler — liste canlı güncellenir', () async {
      cubit.start();
      await flush();

      expect(
        await cubit.saveCourse(
          courseCode: 'VY301',
          courseName: 'Veri Yapıları',
          instructorName: 'Meltem Hoca',
          roomLocation: 'B-12',
          dayOfWeek: 1,
          startTime: '08:30',
          endTime: '10:00',
        ),
        isTrue,
      );
      await flush();
      expect(cubit.state.coursesOfSelectedDay.map((c) => c.courseCode), ['VY301', 'MOB101'], reason: 'saate göre sıralı');

      await cubit.saveCourse(
        courseId: 'c-mob',
        courseCode: 'MOB101',
        courseName: 'Mobil Programlama',
        instructorName: 'Fahri Hoca',
        roomLocation: 'D-210',
        dayOfWeek: 1,
        startTime: '10:30',
        endTime: '12:00',
      );
      await flush();
      expect(cubit.state.courses.firstWhere((c) => c.courseId == 'c-mob').roomLocation, 'D-210');
      expect(cubit.state.actionMessage, 'Ders güncellendi.');

      await cubit.removeCourse('c-mob');
      await flush();
      expect(cubit.state.courses.any((c) => c.courseId == 'c-mob'), isFalse);
    });

    test('ders kodu boşsa depoya gidilmez', () async {
      final ok = await cubit.saveCourse(
        courseCode: ' ',
        courseName: 'X',
        instructorName: 'Y',
        roomLocation: 'Z',
        dayOfWeek: 1,
        startTime: '08:00',
        endTime: '09:00',
      );
      expect(ok, isFalse);
      expect(repo.courses.items.length, 2);
    });

    test('akış hatası failure durumuna düşer', () async {
      repo.courses.streamError = Exception('permission-denied');
      cubit.start();
      await flush();
      expect(cubit.state.status, ViewStatus.failure);
    });
  });

  group('WeeklySchedulePage', () {
    late TestBackend backend;
    setUp(() async {
      backend = TestBackend();
      await backend.register();
    });

    testWidgets('öğrenci düzenle / sil / ekle butonlarını görmez', (tester) async {
      await pumpPage(tester, const WeeklySchedulePage(), backend: backend);
      expect(find.byKey(const Key('schedule_add_course')), findsNothing);
    });

    testWidgets('eğitmen "Yeni Ders Ekle" butonunu görür', (tester) async {
      await pumpPage(tester, const WeeklySchedulePage(), backend: backend, role: UserRole.instructor);
      expect(find.byKey(const Key('schedule_add_course')), findsOneWidget);
    });

    testWidgets('ders olmayan günde boş durum gösterilir', (tester) async {
      backend.schedule.courses.items.clear();
      await pumpPage(tester, const WeeklySchedulePage(), backend: backend);
      expect(find.text('Bu gün ders yok'), findsOneWidget);
    });
  });
}
