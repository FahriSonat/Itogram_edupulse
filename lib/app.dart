import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/widgets/state_views/loading_state_view.dart';
import 'features/announcements/presentation/cubit/announcement_cubit.dart';
import 'features/assignments/presentation/cubit/assignment_cubit.dart';
import 'features/attendance/presentation/cubit/absence_control_cubit.dart';
import 'features/attendance/presentation/cubit/live_attendance_cubit.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/pages/intro_onboarding_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/forum/presentation/cubit/forum_cubit.dart';
import 'features/grades/presentation/cubit/grades_cubit.dart';
import 'features/schedule/presentation/cubit/schedule_cubit.dart';
import 'features/shell/main_shell_page.dart';

/// Açılış akışı: animasyonlu splash → (ilk açılışta) tanıtım → giriş / ana panel.
enum AppStage { splash, intro, ready }

/// [EduPulseApp] kök widget: tema, oturum ve tüm modül Cubit'lerini sağlar;
/// splash → onboarding → kimlik doğrulama geçişlerini yönetir.
///
/// Çalıştırmadan önce [initDependencies] çağrılmış olmalıdır (bkz. `main.dart`).
class EduPulseApp extends StatefulWidget {
  const EduPulseApp({super.key});

  @override
  State<EduPulseApp> createState() => _EduPulseAppState();
}

class _EduPulseAppState extends State<EduPulseApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthCubit _authCubit = sl<AuthCubit>()..restoreSession();
  late final AppRouter _router = AppRouter(_authCubit);
  AppStage _stage = AppStage.splash;

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  void _onSplashFinished() {
    final seen = sl<AuthRepository>().hasSeenOnboarding();
    setState(() => _stage = seen ? AppStage.ready : AppStage.intro);
  }

  Future<void> _onIntroFinished() async {
    await sl<AuthRepository>().markOnboardingSeen();
    if (mounted) setState(() => _stage = AppStage.ready);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(sl<LocalStorageService>())),
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider(create: (_) => createNotificationCubit(_authCubit)),
        BlocProvider(create: (_) => sl<ScheduleCubit>()),
        BlocProvider(create: (_) => sl<AnnouncementCubit>()),
        BlocProvider(create: (_) => sl<AssignmentCubit>()),
        BlocProvider(create: (_) => sl<LiveAttendanceCubit>()),
        BlocProvider(create: (_) => sl<AbsenceControlCubit>()),
        BlocProvider(create: (_) => sl<GradesCubit>()),
        BlocProvider(create: (_) => sl<ForumCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: _navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            // macOS / masaüstü: fareyle sürükleyerek yatay liste / PageView kaydırma
            scrollBehavior: const AppScrollBehavior(),
            onGenerateRoute: _router.onGenerateRoute,
            onUnknownRoute: _router.onUnknownRoute,
            // AppBar'sız ekranlarda (Splash, Intro) da status bar ikonları temaya uysun
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: AppTheme.systemOverlayFor(Theme.of(context).brightness),
              child: child ?? const SizedBox.shrink(),
            ),
            home: BlocConsumer<AuthCubit, AuthState>(
              // Çıkışta açık detay sayfaları kapatılır; kökte giriş ekranı kalır.
              listenWhen: (prev, curr) => prev.isAuthenticated && !curr.isAuthenticated,
              listener: (_, _) => _navigatorKey.currentState?.popUntil((route) => route.isFirst),
              // Giriş sürerken (submitting) aynı anahtarlı LoginPage korunur; durum kaybolmaz.
              builder: (context, auth) =>
                  AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: _buildStage(auth)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStage(AuthState auth) {
    switch (_stage) {
      case AppStage.splash:
        return SplashPage(key: const ValueKey('splash_screen'), onFinish: _onSplashFinished);
      case AppStage.intro:
        return IntroOnboardingPage(key: const ValueKey('intro_screen'), onGetStarted: _onIntroFinished);
      case AppStage.ready:
        if (auth.status == AuthStatus.unknown) {
          return const Scaffold(key: ValueKey('session_check'), body: LoadingStateView(isShimmer: false));
        }
        final user = auth.user;
        if (auth.isAuthenticated && user != null) {
          return MainShellPage(key: ValueKey('shell_${user.uid}'), user: user);
        }
        return const LoginPage(key: ValueKey('login_screen'));
    }
  }
}
