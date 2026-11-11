import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/app.dart';
import 'package:itogram_edupulse/core/di/injection_container.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/absence_control_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/pages/live_attendance_page.dart';
import 'package:itogram_edupulse/features/attendance/presentation/widgets/dynamic_qr_pin_board.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/login_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/splash_page.dart';
import 'package:itogram_edupulse/features/shell/main_shell_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _bootApp(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await tester.runAsync(initDependencies);
  // Telefon boyutunda ekran: taşma (overflow) hataları testte yakalanır.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const EduPulseApp());
}

/// Splash animasyonunu (2.6 sn) ve geçişleri ilerletir.
Future<void> _skipSplash(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('EduPulseApp açılışta splash ekranını gösterir', (tester) async {
    await _bootApp(tester);
    await tester.pump();
    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('öğrenci demo hesabıyla giriş yapıp ana panele ulaşır', (tester) async {
    await _bootApp(tester, prefs: {'edupulse_onboarding_seen': true});
    await _skipSplash(tester);
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '202604001');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Giriş Yap'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(MainShellPage), findsOneWidget);
    expect(find.textContaining('Ayberk'), findsWidgets);
  });

  testWidgets('eğitmen giriş yapar, canlı yoklama başlatır ve PIN panosu görünür', (tester) async {
    await _bootApp(tester, prefs: {'edupulse_onboarding_seen': true});
    await _skipSplash(tester);

    await tester.tap(find.text('Eğitmen / Yönetici'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), '1001');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Giriş Yap'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MainShellPage), findsOneWidget);

    // Alt menüdeki tüm sekmeleri gez (taşma / çalışma zamanı hatası olmamalı).
    for (final tab in ['Dersler', 'Ödevler', 'Forum', 'Notlar', 'Ana Sayfa']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.tap(find.text('Yoklamayı Başlat').first);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(LiveAttendancePage), findsOneWidget);

    final startButton = find.textContaining('için Yoklamayı Başlat');
    await tester.scrollUntilVisible(
      startButton,
      200,
      scrollable: find.descendant(of: find.byType(LiveAttendancePage), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(startButton);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(DynamicQrPinBoard), findsOneWidget);
    expect(find.textContaining('MOB101'), findsWidgets);
  });

  testWidgets('öğrenci devamsızlık ve canlı yoklama sayfalarını açar', (tester) async {
    await _bootApp(tester, prefs: {'edupulse_onboarding_seen': true});
    await _skipSplash(tester);
    await tester.enterText(find.byType(TextFormField).at(0), '202604001');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Giriş Yap'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pushNamed('/absence-control');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(AbsenceControlPage), findsOneWidget);
    expect(find.text('Ders Bazlı Devamsızlık'), findsOneWidget);

    navigator.pushNamed('/live-attendance');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(LiveAttendancePage), findsOneWidget);

    // Öğrenci eğitmene özel değerlendirme sayfasını açamaz (Kural 5).
    navigator.pushNamed('/assignments/grading', arguments: 'as_theme');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Yetkisiz Erişim'), findsOneWidget);
  });

  testWidgets('öğrenci hesabı eğitmen portalından giriş yapamaz (Kural 5)', (tester) async {
    await _bootApp(tester, prefs: {'edupulse_onboarding_seen': true});
    await _skipSplash(tester);

    await tester.tap(find.text('Eğitmen / Yönetici'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), '202604001');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Giriş Yap'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(MainShellPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.textContaining('öğrenci hesabıdır'), findsOneWidget);
  });
}
