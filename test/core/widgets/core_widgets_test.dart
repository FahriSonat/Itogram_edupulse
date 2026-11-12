import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/services/local_storage_service.dart';
import 'package:itogram_edupulse/core/theme/app_theme.dart';
import 'package:itogram_edupulse/core/theme/theme_cubit.dart';
import 'package:itogram_edupulse/core/widgets/app_drawer_menu.dart';
import 'package:itogram_edupulse/core/widgets/countdown_timer_widget.dart';
import 'package:itogram_edupulse/core/widgets/custom_app_bar.dart';
import 'package:itogram_edupulse/core/widgets/dashboard/portal_avatar.dart';
import 'package:itogram_edupulse/core/widgets/main_scaffold_shell.dart';
import 'package:itogram_edupulse/core/widgets/role_visibility_guard.dart';
import 'package:itogram_edupulse/core/widgets/state_views/empty_state_view.dart';
import 'package:itogram_edupulse/core/widgets/state_views/error_state_view.dart';
import 'package:itogram_edupulse/core/widgets/state_views/loading_state_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/design_test_harness.dart';

void main() {
  group('RoleVisibilityGuard (Kural 5 — Arayüz Blokajı)', () {
    testWidgets('öğrenci için eğitmen builder\'ı hiç çağrılmaz', (tester) async {
      var instructorBuilt = false;
      await pumpDesign(
        tester,
        RoleVisibilityGuard(
          currentRole: UserRole.student,
          studentBuilder: (_) => const Text('Ödevi Yükle'),
          instructorBuilder: (_) {
            instructorBuilt = true;
            return const Text('Not Gir');
          },
        ),
      );
      expect(find.text('Ödevi Yükle'), findsOneWidget);
      expect(find.text('Not Gir'), findsNothing);
      expect(instructorBuilt, isFalse, reason: 'Yetkisiz widget ağacı hiç oluşturulmamalı');
    });

    testWidgets('eğitmen ve admin yalnızca kendi görünümünü görür', (tester) async {
      await pumpDesign(
        tester,
        RoleVisibilityGuard(
          currentRole: UserRole.instructor,
          studentBuilder: (_) => const Text('PIN Gir'),
          instructorBuilder: (_) => const Text('Yoklamayı Başlat'),
          adminBuilder: (_) => const Text('Sistem Ayarları'),
        ),
      );
      expect(find.text('Yoklamayı Başlat'), findsOneWidget);
      expect(find.text('PIN Gir'), findsNothing);
      expect(find.text('Sistem Ayarları'), findsNothing);

      await pumpDesign(
        tester,
        RoleVisibilityGuard(
          currentRole: UserRole.admin,
          studentBuilder: (_) => const Text('PIN Gir'),
          instructorBuilder: (_) => const Text('Yoklamayı Başlat'),
          adminBuilder: (_) => const Text('Sistem Ayarları'),
        ),
      );
      expect(find.text('Sistem Ayarları'), findsOneWidget);
      expect(find.text('Yoklamayı Başlat'), findsNothing);
    });

    testWidgets('onlyInstructor öğrenciye fallback (boş alan) çizer', (tester) async {
      await pumpDesign(
        tester,
        Column(
          children: [
            RoleVisibilityGuard.onlyInstructor(currentRole: UserRole.student, child: const Text('Kriz Yayını Gönder')),
            RoleVisibilityGuard.onlyStudent(currentRole: UserRole.student, child: const Text('Soru Sor')),
          ],
        ),
      );
      expect(find.text('Kriz Yayını Gönder'), findsNothing);
      expect(find.text('Soru Sor'), findsOneWidget);
    });
  });

  group('CountdownTimerWidget', () {
    test('Saat:Dakika:Saniye ve okunur biçimler', () {
      expect(CountdownTimerWidget.formatClock(const Duration(hours: 1, minutes: 5, seconds: 9)), '01:05:09');
      expect(CountdownTimerWidget.formatClock(const Duration(seconds: -5)), '00:00:00');
      expect(CountdownTimerWidget.formatHuman(const Duration(seconds: 45)), '45 saniye kaldı');
      expect(CountdownTimerWidget.formatHuman(const Duration(minutes: 2, seconds: 5)), '2 dk 05 sn kaldı');
      expect(CountdownTimerWidget.formatHuman(const Duration(hours: 3, minutes: 10)), '3 sa 10 dk kaldı');
      expect(CountdownTimerWidget.formatHuman(const Duration(days: 2, hours: 4)), '2 gün 4 sa kaldı');
      expect(CountdownTimerWidget.formatHuman(Duration.zero), AppStrings.countdownExpired);
    });

    testWidgets('60 saniyeden geri sayar ve onFinished yalnızca bir kez çağrılır', (tester) async {
      var finished = 0;
      await pumpDesign(tester, CountdownTimerWidget(initialSeconds: 60, onFinished: () => finished++));
      expect(find.text('1 dk 00 sn kaldı'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('59 saniye kaldı'), findsOneWidget);

      await tester.pump(const Duration(seconds: 59));
      expect(find.text(AppStrings.countdownExpired), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(finished, 1);
    });

    testWidgets('dispose sonrası timer iptal edilir (setState after dispose yok)', (tester) async {
      await pumpDesign(tester, const CountdownTimerWidget(initialSeconds: 30));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 40));
      expect(tester.takeException(), isNull);
    });

    testWidgets('showClockFormat SS:DD:SS gösterir', (tester) async {
      await pumpDesign(tester, const CountdownTimerWidget(initialSeconds: 3725, showClockFormat: true));
      expect(find.text('01:02:05'), findsOneWidget);
    });
  });

  group('4 Durum Kalkanı (state views)', () {
    testWidgets('LoadingStateView shimmer iskeleti küçük alanda taşma üretmez', (tester) async {
      await pumpDesign(
        tester,
        const SizedBox(height: 120, child: LoadingStateView()),
        scrollable: false,
        size: const Size(320, 640),
        textScale: 1.3,
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel(AppStrings.loadingMessage), findsOneWidget);
    });

    testWidgets('LoadingStateView spinner modu mesajı gösterir', (tester) async {
      await pumpDesign(
        tester,
        const LoadingStateView(isShimmer: false, message: 'Notlar yükleniyor'),
        scrollable: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Notlar yükleniyor'), findsOneWidget);
    });

    testWidgets('ErrorStateView "Tekrar Dene" butonu onRetry çağırır', (tester) async {
      var retried = false;
      await pumpDesign(
        tester,
        ErrorStateView(message: 'Bağlantı hatası', onRetry: () => retried = true),
        scrollable: false,
      );
      expect(find.text('Bağlantı hatası'), findsOneWidget);
      await tester.tap(find.text(AppStrings.retryButton));
      expect(retried, isTrue);
    });

    testWidgets('ErrorStateView onRetry yoksa buton göstermez', (tester) async {
      await pumpDesign(tester, const ErrorStateView(), scrollable: false);
      expect(find.text(AppStrings.retryButton), findsNothing);
      expect(find.text(ErrorStateView.defaultTitle), findsOneWidget);
    });

    testWidgets('EmptyStateView illüstrasyon, metin ve eylem butonu çizer', (tester) async {
      var tapped = false;
      await pumpDesign(
        tester,
        EmptyStateView(title: 'Ödev yok', actionLabel: 'Yeni Ödev', onAction: () => tapped = true),
        scrollable: false,
      );
      expect(find.text('Ödev yok'), findsOneWidget);
      expect(find.text(AppStrings.emptyListSubtitle), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is EmptyIllustrationPainter), findsOneWidget);
      await tester.tap(find.text('Yeni Ödev'));
      expect(tapped, isTrue);
    });

    testWidgets('state view\'lar hiçbir ekran koşulunda taşmaz', (tester) async {
      await expectNoLayoutErrors(tester, () => const EmptyStateView(), scrollable: false);
      await expectNoLayoutErrors(tester, () => ErrorStateView(onRetry: () {}), scrollable: false);
      await expectNoLayoutErrors(tester, () => const LoadingStateView(isShimmer: false), scrollable: false);
    });
  });

  group('MainScaffoldShell + AppDrawerMenu + CustomAppBar + PortalAvatar', () {
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorageService(await SharedPreferences.getInstance());
    });

    Future<void> pumpShell(
      WidgetTester tester, {
      UserRole role = UserRole.student,
      int index = 0,
      ValueChanged<int>? onTab,
      ValueChanged<String>? onNavigate,
      VoidCallback? onLogout,
      Size size = const Size(360, 780),
    }) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final cubit = ThemeCubit(storage);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              home: MainScaffoldShell(
                title: 'Ders Programı',
                currentIndex: index,
                userRole: role,
                userName: 'Test Kullanıcı',
                userEmailOrNo: '2026 • Test',
                onNavigationIndexChanged: onTab ?? (_) {},
                onDrawerNavigate: onNavigate ?? (_) {},
                onLogout: onLogout ?? () {},
                child: const Center(child: Text('içerik')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    test('rota ↔ sekme eşlemesi şartname rotalarını kullanır', () {
      expect(MainScaffoldShell.tabRoutes, ['/home', '/schedule', '/assignments', '/forum', '/grades']);
      expect(MainScaffoldShell.indexForRoute('/forum'), 3);
      expect(MainScaffoldShell.indexForRoute('/forum/question'), 3);
      expect(MainScaffoldShell.indexForRoute('/live-attendance'), -1);
    });

    testWidgets('GoRouter ShellRoute içinde MainScaffoldShell(child: child) doğrudan çalışır', (tester) async {
      tester.view.physicalSize = const Size(360, 780) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainScaffoldShell(child: child),
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const Center(child: Text('Ana Ekran'))),
              GoRoute(path: '/grades', builder: (_, _) => const Center(child: Text('Not Ekranı'))),
              GoRoute(path: '/live-attendance', builder: (_, _) => const Center(child: Text('Yoklama Ekranı'))),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Ana Ekran'), findsOneWidget);

      await tester.tap(find.text(AppStrings.tabGrades));
      await tester.pumpAndSettle();
      expect(find.text('Not Ekranı'), findsOneWidget);
      expect(find.text(AppStrings.navGrades), findsOneWidget);

      router.go('/live-attendance');
      await tester.pumpAndSettle();
      expect(find.text('Yoklama Ekranı'), findsOneWidget);
      expect(find.text(AppStrings.navLiveAttendance), findsOneWidget);
    });

    testWidgets('kalıcı BottomNavigationBar 5 sekme içerir ve dokunuşu bildirir', (tester) async {
      int? tapped;
      await pumpShell(tester, onTab: (i) => tapped = i);

      final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(nav.items.map((i) => i.label), [
        AppStrings.tabHome,
        AppStrings.tabSchedule,
        AppStrings.tabAssignments,
        AppStrings.tabForum,
        AppStrings.tabGrades,
      ]);
      await tester.tap(find.text(AppStrings.tabForum));
      expect(tapped, 3);
    });

    testWidgets('AppBar rol rozeti student, instructor ve admin için tam metni gösterir', (tester) async {
      await pumpShell(tester, role: UserRole.instructor, size: const Size(320, 640));
      expect(find.text(AppStrings.instructorPortal), findsOneWidget);
      expect(find.text('Ders Programı'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpShell(tester, role: UserRole.student);
      expect(find.text(AppStrings.studentPortal), findsOneWidget);

      await pumpShell(tester, role: UserRole.admin);
      expect(find.text(AppStrings.adminPortal), findsOneWidget);
    });

    testWidgets('PortalAvatar her rol için doğru semantik etiketi üretir', (tester) async {
      await pumpDesign(tester, const PortalAvatar(role: UserRole.admin));
      expect(find.bySemanticsLabel('Yönetici avatarı'), findsOneWidget);
    });

    testWidgets('açılır menü 7 ekran bağlantısını şartname sırasıyla listeler', (tester) async {
      String? navigated;
      await pumpShell(tester, onNavigate: (r) => navigated = r);

      await tester.tap(find.byTooltip(const DefaultMaterialLocalizations().openAppDrawerTooltip));
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawerMenu), findsOneWidget);
      for (final d in AppDrawerMenu.destinations) {
        expect(find.text(d.title), findsOneWidget, reason: d.title);
      }
      expect(AppDrawerMenu.destinations.map((d) => d.title), [
        'Ana Sayfa (Duyurular)',
        'Ders Programı',
        'Canlı Yoklama',
        'Ödev Kontrol',
        'Devamsızlık Kontrol',
        'Not Bilgisi',
        'Kampüs Forumu',
      ]);
      expect(find.text(AppStrings.navLogout), findsOneWidget);
      expect(find.text('Test Kullanıcı'), findsOneWidget);

      await tester.tap(find.text('Canlı Yoklama'));
      await tester.pumpAndSettle();
      expect(navigated, '/live-attendance');
    });

    testWidgets('menüdeki tema değiştirici ThemeCubit üzerinden koyu temaya geçirir', (tester) async {
      await pumpShell(tester);
      await tester.tap(find.byTooltip(const DefaultMaterialLocalizations().openAppDrawerTooltip));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.themeLight), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Karanlık tema'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.themeDark), findsOneWidget);
      expect(await storage.getThemeMode(), 'dark');
    });

    testWidgets('Çıkış Yap menüyü kapatıp onLogout çağırır', (tester) async {
      var loggedOut = false;
      await pumpShell(tester, onLogout: () => loggedOut = true);
      await tester.tap(find.byTooltip(const DefaultMaterialLocalizations().openAppDrawerTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.navLogout));
      await tester.pumpAndSettle();
      expect(loggedOut, isTrue);
      expect(find.byType(AppDrawerMenu), findsNothing);
    });

    testWidgets('CustomAppBar bildirim rozeti okunmamış sayıyı gösterir', (tester) async {
      await pumpDesign(
        tester,
        Scaffold(
          appBar: CustomAppBar(
            title: 'Başlık',
            currentRole: UserRole.student,
            unreadNotificationCount: 12,
            onNotificationPressed: () {},
          ),
        ),
        scrollable: false,
      );
      expect(find.text('9+'), findsOneWidget);
      expect(find.byTooltip(AppStrings.notifications), findsOneWidget);
    });
  });
}

