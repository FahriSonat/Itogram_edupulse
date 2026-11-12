// Geliştirici 2 (UI/UX — Ayberk) bileşenleri için QA testleri (Geliştirici 6).
//
// Kapsam: Ana sayfa dashboard kartları, marka (logo), tema anahtarı, ortak
// kart/başlık, rol rozeti, duyuru türü rozeti, kampüs sahnesi ve onboarding
// illüstrasyonları. Her bileşen için:
//   1) Doğru veriyi gösteriyor mu?
//   2) Dokunma (onTap) geri çağrıları çalışıyor mu?
//   3) Açık / koyu tema + dar ekran + büyük yazıda taşma (overflow) yok mu?

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/announcement_type.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/theme/app_scroll_behavior.dart';
import 'package:itogram_edupulse/core/widgets/animations/fade_slide_in.dart';
import 'package:itogram_edupulse/core/widgets/atmosphere/ambient_background.dart';
import 'package:itogram_edupulse/core/widgets/atmosphere/campus_scene.dart';
import 'package:itogram_edupulse/core/widgets/brand/edupulse_logo.dart';
import 'package:itogram_edupulse/core/widgets/custom_app_bar.dart';
import 'package:itogram_edupulse/core/widgets/dashboard/instructor_dashboard_hero.dart';
import 'package:itogram_edupulse/core/widgets/dashboard/metric_badge_card.dart';
import 'package:itogram_edupulse/core/widgets/dashboard/next_class_highlight_card.dart';
import 'package:itogram_edupulse/core/widgets/dashboard/student_dashboard_hero.dart';
import 'package:itogram_edupulse/core/widgets/edu_card.dart';
import 'package:itogram_edupulse/core/widgets/section_header.dart';
import 'package:itogram_edupulse/core/widgets/theme_toggle_switch.dart';
import 'package:itogram_edupulse/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:itogram_edupulse/features/auth/presentation/widgets/onboarding_illustrations.dart';

import '../../helpers/design_test_harness.dart';

/// Giriş animasyonlarının (FadeSlideIn, logo çizimi) bitmesini bekler.
/// `repeat()` eden illüstrasyonlar yüzünden pumpAndSettle kullanılmaz.
Future<void> _finishIntroAnimations(WidgetTester tester) => tester.pump(const Duration(seconds: 2));

void main() {
  group('EduCard', () {
    testWidgets('içeriği çizer ve onTap tetiklenir', (tester) async {
      var tapped = 0;
      await pumpDesign(tester, EduCard(onTap: () => tapped++, child: const Text('Kart İçeriği')));

      expect(find.text('Kart İçeriği'), findsOneWidget);
      await tester.tap(find.text('Kart İçeriği'));
      expect(tapped, 1);
    });

    testWidgets('onTap verilmezse dokunma hata fırlatmaz', (tester) async {
      await pumpDesign(tester, const EduCard(child: Text('Pasif Kart')));
      await tester.tap(find.text('Pasif Kart'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('gradyan, tint ve highlighted varyantları her temada taşmaz', (tester) async {
      await expectNoLayoutErrors(
        tester,
        () => const Column(
          children: [
            EduCard(child: Text('Varsayılan')),
            EduCard(tint: Color(0xFFE0F2FE), child: Text('Pastel')),
            EduCard(highlighted: true, glowColor: Colors.green, child: Text('Öne çıkan')),
            EduCard(gradient: LinearGradient(colors: [Colors.blue, Colors.indigo]), child: Text('Gradyan')),
          ],
        ),
      );
    });
  });

  group('SectionHeader', () {
    testWidgets('başlık + "Tümü" aksiyonu çalışır', (tester) async {
      var actions = 0;
      await pumpDesign(tester, SectionHeader(title: 'Bugünkü Derslerim', actionLabel: 'Tümü', onAction: () => actions++));

      expect(find.text('Bugünkü Derslerim'), findsOneWidget);
      await tester.tap(find.text('Tümü'));
      expect(actions, 1);
    });

    testWidgets('actionLabel yoksa buton çizilmez', (tester) async {
      await pumpDesign(tester, const SectionHeader(title: 'Duyurular'));
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('çok uzun başlık tek satırda kesilir, taşmaz', (tester) async {
      await expectNoLayoutErrors(
        tester,
        () => SectionHeader(title: 'Çok ' * 40, actionLabel: 'Tümü', onAction: () {}),
      );
    });
  });

  group('ThemeToggleSwitch', () {
    testWidgets('dokunulunca ters değeri bildirir (açık → koyu)', (tester) async {
      bool? received;
      await pumpDesign(tester, ThemeToggleSwitch(isDark: false, onChanged: (v) => received = v));

      await tester.tap(find.byType(ThemeToggleSwitch));
      expect(received, isTrue);
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    });

    testWidgets('koyu temadayken dokunulunca false bildirir', (tester) async {
      bool? received;
      await pumpDesign(tester, ThemeToggleSwitch(isDark: true, onChanged: (v) => received = v));

      await tester.tap(find.byType(ThemeToggleSwitch));
      expect(received, isFalse);
    });

    testWidgets('erişilebilirlik: "Karanlık tema" etiketi ve toggled durumu vardır', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDesign(tester, ThemeToggleSwitch(isDark: true, onChanged: (_) {}));

      final node = tester.getSemantics(find.bySemanticsLabel('Karanlık tema'));
      expect(node.flagsCollection.isToggled, isNotNull);
      handle.dispose();
    });
  });

  group('RoleBadge (CustomAppBar rol rozeti)', () {
    for (final role in UserRole.values) {
      testWidgets('${role.name} için doğru portal etiketi', (tester) async {
        await pumpDesign(tester, RoleBadge(role: role));
        expect(find.bySemanticsLabel(AppStrings.portalBadge(role)), findsOneWidget);
      });
    }

    testWidgets('tüm roller her temada taşmaz', (tester) async {
      await expectNoLayoutErrors(
        tester,
        () => const Wrap(children: [
          RoleBadge(role: UserRole.student),
          RoleBadge(role: UserRole.instructor),
          RoleBadge(role: UserRole.admin),
        ]),
      );
    });
  });

  group('AnnouncementTypeBadge', () {
    for (final type in AnnouncementType.values) {
      testWidgets('${type.name} türü doğru etiketi gösterir', (tester) async {
        await pumpDesign(tester, AnnouncementTypeBadge(type: type));
        expect(find.text(AppStrings.announcementType(type)), findsOneWidget);
      });
    }
  });

  group('MetricBadgeCard', () {
    testWidgets('değer + etiket gösterir ve dokunma çalışır', (tester) async {
      var tapped = 0;
      await pumpDesign(
        tester,
        SizedBox(
          width: 110,
          child: MetricBadgeCard(
            value: '%92',
            label: AppStrings.attendanceRate,
            icon: Icons.check_circle_rounded,
            accentColor: Colors.green,
            onTap: () => tapped++,
          ),
        ),
      );

      expect(find.text('%92'), findsOneWidget);
      expect(find.text(AppStrings.attendanceRate), findsOneWidget);
      await tester.tap(find.text('%92'));
      expect(tapped, 1);
    });

    testWidgets('dar kutuda uzun değer/etiket taşmaz', (tester) async {
      await expectNoLayoutErrors(
        tester,
        () => const Row(
          children: [
            Expanded(
              child: MetricBadgeCard(
                value: '100000.00',
                label: 'Çok uzun bir metrik etiketi',
                icon: Icons.star,
                accentColor: Colors.pink,
              ),
            ),
            Expanded(child: MetricBadgeCard(value: '3', label: 'Ödev', icon: Icons.book, accentColor: Colors.purple)),
            Expanded(child: MetricBadgeCard(value: '3.42', label: 'GPA', icon: Icons.school, accentColor: Colors.red)),
          ],
        ),
      );
    });
  });

  group('NextClassHighlightCard (Modül 1.1 — Derse kalan süre)', () {
    testWidgets('ders adı, saat/amfi ve "Sıradaki Ders" rozetini gösterir', (tester) async {
      await pumpDesign(
        tester,
        NextClassHighlightCard(
          courseName: 'Flutter ile Mobil Geliştirme',
          timeAndRoom: '10:30 - 12:00 • D-107',
          startTime: DateTime.now().add(const Duration(hours: 2, minutes: 5)),
        ),
      );

      expect(find.text('Flutter ile Mobil Geliştirme'), findsOneWidget);
      expect(find.text('10:30 - 12:00 • D-107'), findsOneWidget);
      expect(find.text(AppStrings.nextCourse), findsOneWidget);
      expect(find.textContaining('sa'), findsWidgets);
      expect(find.textContaining('kaldı'), findsOneWidget);
    });

    testWidgets('1 saatten az kaldıysa dakika cinsinden yazar', (tester) async {
      await pumpDesign(
        tester,
        NextClassHighlightCard(
          courseName: 'Veri Yapıları',
          timeAndRoom: '13:00 • A204',
          startTime: DateTime.now().add(const Duration(minutes: 30, seconds: 30)),
        ),
      );
      expect(find.textContaining('dakika kaldı'), findsOneWidget);
    });

    testWidgets('ders saati geçtiyse "Ders başladı" yazar', (tester) async {
      await pumpDesign(
        tester,
        NextClassHighlightCard(
          courseName: 'Algoritmalar',
          timeAndRoom: '09:00 • B101',
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      expect(find.text('Ders başladı'), findsOneWidget);
    });

    testWidgets('karta dokununca onTap çalışır', (tester) async {
      var tapped = 0;
      await pumpDesign(
        tester,
        NextClassHighlightCard(
          courseName: 'Mobil Programlama',
          timeAndRoom: '10:30 • D-107',
          startTime: DateTime.now().add(const Duration(hours: 1)),
          onTap: () => tapped++,
        ),
      );
      await tester.tap(find.text('Mobil Programlama'));
      expect(tapped, 1);
    });

    testWidgets('uzun ders adı her temada taşmaz', (tester) async {
      await expectNoLayoutErrors(
        tester,
        () => NextClassHighlightCard(
          courseName: 'Çok Uzun Bir Ders Adı ' * 6,
          timeAndRoom: '10:30 - 12:00 • D-107 Mühendislik Fakültesi Büyük Amfi',
          startTime: DateTime.now().add(const Duration(hours: 3)),
        ),
      );
    });
  });

  group('StudentDashboardHero (Öğrenci Portalı Ana Sayfa)', () {
    testWidgets('selamlama, sıradaki ders ve 3 metrik kutusunu gösterir', (tester) async {
      await pumpDesign(
        tester,
        StudentDashboardHero(
          studentName: 'Merve',
          nextCourseName: 'Flutter ile Mobil Geliştirme',
          nextCourseStartTime: DateTime.now().add(const Duration(minutes: 45)),
          attendanceRate: '%88',
          activeAssignments: '4',
          gpa: '3.10',
        ),
      );
      await _finishIntroAnimations(tester);

      expect(find.text('Merve! 👋'), findsOneWidget);
      expect(find.text(AppStrings.studentGreetingSubtitle), findsOneWidget);
      expect(find.text('Flutter ile Mobil Geliştirme'), findsOneWidget);
      expect(find.text('%88'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('3.10'), findsOneWidget);
      expect(find.text(AppStrings.attendanceRate), findsOneWidget);
      expect(find.text(AppStrings.activeAssignments), findsOneWidget);
      expect(find.text('GPA'), findsOneWidget);
    });

    testWidgets('metrik ve ders kartı dokunmaları doğru callback\'i çağırır', (tester) async {
      final taps = <String>[];
      await pumpDesign(
        tester,
        StudentDashboardHero(
          onNextCourseTap: () => taps.add('ders'),
          onAttendanceTap: () => taps.add('katilim'),
          onAssignmentsTap: () => taps.add('odev'),
          onGpaTap: () => taps.add('gpa'),
        ),
      );
      await _finishIntroAnimations(tester);

      await tester.tap(find.text('Flutter ile Mobil Geliştirme'));
      await tester.tap(find.text(AppStrings.attendanceRate));
      await tester.tap(find.text(AppStrings.activeAssignments));
      await tester.tap(find.text('GPA'));
      expect(taps, ['ders', 'katilim', 'odev', 'gpa']);
    });

    testWidgets('her tema ve büyük yazıda taşmaz', (tester) async {
      await expectNoLayoutErrors(
        tester,
        () => StudentDashboardHero(
          studentName: 'Meltem Jülide Taşkıran',
          nextCourseStartTime: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      await _finishIntroAnimations(tester);
    });
  });

  group('InstructorDashboardHero (Eğitmen Yönetim Paneli)', () {
    InstructorDashboardHero build(List<String> taps) => InstructorDashboardHero(
          instructorName: 'Fahri Hoca',
          pendingHomeworksCount: 7,
          classSuccessRate: '%81',
          newQuestionsCount: 2,
          onStartAttendance: () => taps.add('yoklama'),
          onPendingHomeworksTap: () => taps.add('odev'),
          onClassAnalysisTap: () => taps.add('analiz'),
          onSendAnnouncementTap: () => taps.add('duyuru'),
          onQuestionsTap: () => taps.add('soru'),
        );

    testWidgets('Yoklamayı Başlat CTA ve 4 operasyon kartını sayılarla gösterir', (tester) async {
      await pumpDesign(tester, build([]));
      await _finishIntroAnimations(tester);

      expect(find.text(AppStrings.startAttendance), findsOneWidget);
      expect(find.text(AppStrings.qrPinSubtitle), findsOneWidget);
      expect(find.text('7 Bekleyen'), findsOneWidget);
      expect(find.text('%81 Başarı'), findsOneWidget);
      expect(find.text('Tüm sınıfa'), findsOneWidget);
      expect(find.text('2 Yeni Soru'), findsOneWidget);
    });

    testWidgets('her kart kendi callback\'ini çağırır', (tester) async {
      final taps = <String>[];
      await pumpDesign(tester, build(taps));
      await _finishIntroAnimations(tester);

      for (final label in [
        AppStrings.startAttendance,
        AppStrings.pendingHomeworks,
        AppStrings.classAnalysis,
        AppStrings.sendAnnouncement,
        AppStrings.campusQuestions,
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
      }
      expect(taps, ['yoklama', 'odev', 'analiz', 'duyuru', 'soru']);
    });

    testWidgets('her tema ve büyük yazıda taşmaz', (tester) async {
      await expectNoLayoutErrors(tester, () => build([]));
      await _finishIntroAnimations(tester);
    });
  });

  group('Marka: EduPulseLogo / EduPulseWordmark', () {
    testWidgets('showText true iken "Edu" + "Pulse" yazısı çizilir', (tester) async {
      await pumpDesign(tester, const EduPulseLogo());
      await _finishIntroAnimations(tester);
      expect(find.text('Edu'), findsOneWidget);
      expect(find.text('Pulse'), findsOneWidget);
    });

    testWidgets('showText false iken yalnızca simge çizilir', (tester) async {
      await pumpDesign(tester, const EduPulseLogo(showText: false, isAnimated: false));
      expect(find.text('Edu'), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('logo ve wordmark her temada taşmaz', (tester) async {
      await expectNoLayoutErrors(
        tester,
        // Uygulamadaki varsayılan boyutlar (logo 40, wordmark 24).
        () => const Column(children: [EduPulseLogo(), EduPulseWordmark()]),
      );
      await _finishIntroAnimations(tester);
    });
  });

  group('FadeSlideIn', () {
    testWidgets('animasyon sonunda tam görünür olur', (tester) async {
      await pumpDesign(tester, const FadeSlideIn(child: Text('Selam')));
      final fade = tester.widget<FadeTransition>(
        find.ancestor(of: find.text('Selam'), matching: find.byType(FadeTransition)).first,
      );
      expect(fade.opacity.value, lessThan(1));

      await _finishIntroAnimations(tester);
      expect(fade.opacity.value, 1);
    });

    testWidgets('"Hareketi azalt" açıkken animasyonsuz, anında görünür', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(textDirection: TextDirection.ltr, child: FadeSlideIn(child: Text('Hızlı'))),
        ),
      );
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition).first);
      expect(fade.opacity.value, 1);
    });
  });

  group('Atmosfer: CampusScene / AmbientBackground', () {
    testWidgets('gündüz ve gece sahneleri hata vermeden çizilir', (tester) async {
      await expectNoLayoutErrors(
        tester,
        () => const Column(
          children: [
            SizedBox(height: 160, child: CampusScene(isDark: false)),
            SizedBox(height: 160, child: CampusScene(isDark: true, showBuilding: false, fadeTop: true)),
          ],
        ),
      );
    });

    testWidgets('AmbientBackground çocuğunu gösterir', (tester) async {
      await pumpDesign(tester, const AmbientBackground(child: Text('İçerik')), scrollable: false);
      expect(find.text('İçerik'), findsOneWidget);
    });
  });

  group('Onboarding illüstrasyonları', () {
    testWidgets('üç illüstrasyon her temada hatasız çizilir', (tester) async {
      await expectNoLayoutErrors(
        tester,
        () => const Column(
          children: [
            SizedBox(height: 260, child: DualPortalIllustration()),
            SizedBox(height: 260, child: QrCountdownIllustration()),
            SizedBox(height: 260, child: GradeCurveIllustration()),
          ],
        ),
      );
      // Sürekli dönen animasyonlar birkaç kare ilerletildiğinde de hata vermemeli.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });

  test('AppScrollBehavior fareyle sürüklemeyi açar, dokunmatiği korur', () {
    const behavior = AppScrollBehavior();
    expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
  });
}
