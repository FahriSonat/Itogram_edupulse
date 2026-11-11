import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/announcement_type.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:itogram_edupulse/features/announcements/presentation/widgets/create_announcement_sheet.dart';
import 'package:itogram_edupulse/features/announcements/presentation/widgets/crisis_broadcast_bottom_sheet.dart';
import 'package:itogram_edupulse/features/announcements/presentation/widgets/interactive_event_calendar.dart';
import 'package:itogram_edupulse/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:itogram_edupulse/features/auth/presentation/widgets/role_selection_toggle.dart';

import '../../helpers/design_test_harness.dart';

void main() {
  group('AnnouncementCard', () {
    testWidgets('tür rozeti, hedef ders ve "Takvime Ekle" butonu', (tester) async {
      var added = false;
      await pumpDesign(
        tester,
        AnnouncementCard(
          title: 'Flutter Etkinliği',
          content: 'Clean Architecture üzerine.',
          type: AnnouncementType.event,
          eventDate: DateTime(2026, 11, 12),
          authorName: 'Akademi',
          targetLabel: 'MOB101',
          onAddToCalendar: () => added = true,
        ),
      );
      expect(find.text('Etkinlik'), findsOneWidget);
      expect(find.text('12.11.2026'), findsOneWidget);
      expect(find.text('MOB101'), findsOneWidget);
      await tester.tap(find.text('Takvime Ekle'));
      expect(added, isTrue);
    });

    testWidgets('acil duyurusunda "Takvime Ekle" gösterilmez', (tester) async {
      await pumpDesign(
        tester,
        AnnouncementCard(
          title: 'Ders iptal',
          content: 'Kar tatili',
          type: AnnouncementType.urgent,
          eventDate: DateTime(2026, 11, 12),
          onAddToCalendar: () {},
        ),
      );
      expect(find.text('Acil'), findsOneWidget);
      expect(find.text('Takvime Ekle'), findsNothing);
    });

    test('tüm duyuru türlerinin etiketi var', () {
      expect(AnnouncementType.values.map(AppStrings.announcementType), [
        'Genel',
        'Sınav',
        'Ödev',
        'Etkinlik',
        'Acil',
      ]);
    });
  });

  group('CreateAnnouncementSheet', () {
    testWidgets('boş targets listesi ile açıldığında hata fırlatmaz ve yayınlamaz', (tester) async {
      var called = false;
      await pumpDesign(
        tester,
        CreateAnnouncementSheet(
          targets: const [],
          onCreate: ({
            required title,
            required content,
            required type,
            required eventDate,
            required targetCourse,
          }) async => called = true,
        ),
        scrollable: false,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Duyuruyu Yayınla'));
      await tester.tap(find.text('Duyuruyu Yayınla'));
      await tester.pump();
      expect(called, isFalse);
    });
  });

  group('InteractiveEventCalendar', () {
    final today = DateTime(2026, 11, 11); // Çarşamba

    testWidgets('hafta şeridi seçili günü bildirir, oklar haftayı kaydırır', (tester) async {
      DateTime? picked;
      await pumpDesign(
        tester,
        InteractiveEventCalendar(
          selectedDate: today,
          today: today,
          eventDates: {DateTime(2026, 11, 13)},
          onDateSelected: (d) => picked = d,
        ),
      );
      expect(find.text('Kasım 2026'), findsOneWidget);
      expect(find.bySemanticsLabel('13 Kasım, etkinlik var'), findsOneWidget);

      await tester.tap(find.text('13'));
      expect(picked, DateTime(2026, 11, 13));

      await tester.tap(find.byTooltip('Sonraki hafta'));
      await tester.pump();
      expect(find.text('16'), findsOneWidget, reason: 'Pencere bir hafta ileri kaydı (16-29 Kasım)');
      expect(find.text('9'), findsNothing);
    });

    testWidgets('ay görünümü ve "bugün" kısayolu', (tester) async {
      DateTime? picked;
      await pumpDesign(
        tester,
        InteractiveEventCalendar(selectedDate: today, today: today, onDateSelected: (d) => picked = d),
      );
      await tester.tap(find.byTooltip('Ay görünümü'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('30'), findsOneWidget);

      await tester.tap(find.byTooltip('Sonraki ay'));
      await tester.pumpAndSettle();
      expect(find.text('Aralık 2026'), findsOneWidget);

      await tester.tap(find.text('Aralık 2026'));
      await tester.pumpAndSettle();
      expect(picked, today);
      expect(find.text('Kasım 2026'), findsOneWidget);
    });
  });

  group('CrisisBroadcastBottomSheet', () {
    testWidgets('hedef kimliğiyle tek tuşla kriz bildirimi fırlatır', (tester) async {
      Map<String, String>? sent;
      await pumpDesign(
        tester,
        CrisisBroadcastBottomSheet(
          targets: const {'all_campus': 'Tüm Kampüs', 'c101': 'Flutter ile Mobil'},
          onBroadcast: ({required targetId, required targetLabel, required title, required message}) async {
            sent = {'id': targetId, 'label': targetLabel, 'title': title, 'message': message};
          },
        ),
        scrollable: false,
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Kriz Başlığı'), 'Ders İptali');
      await tester.enterText(find.widgetWithText(TextFormField, 'Bildirim Metni'), 'Bugünkü ders yapılmayacak.');
      await tester.pump();
      expect(find.text('Ders İptali'), findsWidgets);

      await tester.ensureVisible(find.text('Anlık Kriz Bildirimini Fırlat'));
      await tester.tap(find.text('Anlık Kriz Bildirimini Fırlat'));
      await tester.pump();
      expect(sent, {
        'id': 'all_campus',
        'label': 'Tüm Kampüs',
        'title': 'Ders İptali',
        'message': 'Bugünkü ders yapılmayacak.',
      });
    });

    testWidgets('başlık/mesaj boşsa göndermez', (tester) async {
      var sent = false;
      await pumpDesign(
        tester,
        CrisisBroadcastBottomSheet(
          targets: const {'all': 'Tüm Kampüs'},
          onBroadcast: ({required targetId, required targetLabel, required title, required message}) async =>
              sent = true,
        ),
        scrollable: false,
      );
      await tester.ensureVisible(find.text('Anlık Kriz Bildirimini Fırlat'));
      await tester.tap(find.text('Anlık Kriz Bildirimini Fırlat'));
      await tester.pump();
      expect(sent, isFalse);
      expect(find.text('Başlık zorunludur'), findsOneWidget);
    });
  });

  group('Auth widget\'ları', () {
    testWidgets('AuthTextField şifreyi gizler ve göster/gizle yapar', (tester) async {
      await pumpDesign(tester, const AuthTextField(label: AppStrings.passwordLabel, isPassword: true));
      EditableText field() => tester.widget<EditableText>(find.byType(EditableText));
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Şifreyi göster'));
      await tester.pump();
      expect(field().obscureText, isFalse);
      expect(find.byTooltip('Şifreyi gizle'), findsOneWidget);
    });

    testWidgets('RoleSelectionToggle "Öğrenci / Kursiyer" ve "Eğitmen / Yönetici" seçtirir', (tester) async {
      UserRole? role;
      await pumpDesign(tester, RoleSelectionToggle(selectedRole: UserRole.student, onRoleChanged: (r) => role = r));
      expect(find.text(AppStrings.studentRole), findsOneWidget);
      await tester.tap(find.text(AppStrings.instructorRole));
      expect(role, UserRole.instructor);
    });
  });

  testWidgets('duyuru ve auth bileşenleri hiçbir ekran koşulunda taşmaz', (tester) async {
    final today = DateTime(2026, 11, 11);
    await expectNoLayoutErrors(
      tester,
      () => AnnouncementCard(
        title: 'Çok uzun bir başlık ' * 5,
        content: 'İçerik ' * 40,
        type: AnnouncementType.exam,
        eventDate: today,
        authorName: 'Prof. Dr. Çok Uzun İsimli Akademisyen',
        targetLabel: 'İleri Seviye Mobil Uygulama Geliştirme',
        onAddToCalendar: () {},
      ),
    );
    await expectNoLayoutErrors(
      tester,
      () => InteractiveEventCalendar(selectedDate: today, today: today, onDateSelected: (_) {}),
    );
    await expectNoLayoutErrors(
      tester,
      () =>
          InteractiveEventCalendar(selectedDate: today, today: today, initiallyExpanded: true, onDateSelected: (_) {}),
    );
    await expectNoLayoutErrors(
      tester,
      () => CrisisBroadcastBottomSheet(
        targets: const {'c1': 'İleri Seviye Mobil Uygulama Geliştirme (Çok Uzun Ders Adı)'},
        onBroadcast: ({required targetId, required targetLabel, required title, required message}) async {},
      ),
      scrollable: false,
    );
    await expectNoLayoutErrors(
      tester,
      () => CreateAnnouncementSheet(
        targets: const ['Tüm Kampüs', 'İleri Seviye Mobil Uygulama Geliştirme'],
        onCreate: ({
          required title,
          required content,
          required type,
          required eventDate,
          required targetCourse,
        }) async {},
      ),
      scrollable: false,
    );
    await expectNoLayoutErrors(
      tester,
      () => RoleSelectionToggle(selectedRole: UserRole.instructor, onRoleChanged: (_) {}),
    );
  });
}

