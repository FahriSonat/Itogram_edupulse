import 'package:itogram_edupulse/core/di/injection_container.dart';
import 'package:itogram_edupulse/core/router/app_router.dart';
import 'package:itogram_edupulse/core/theme/app_theme.dart';
import 'package:itogram_edupulse/core/theme/theme_cubit.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// [EduPulseApp] uygulamanın kök widget'ıdır.
/// 
/// - [AuthCubit] ve [ThemeCubit] sağlayıcılarını uygulamanın en tepesine bağlar.
/// - [MaterialApp.router] ile [AppRouter] yönlendirmesini entegre eder.
/// - Açık ve koyu tema dinamik geçişlerini yönetir.
class EduPulseApp extends StatelessWidget {
  const EduPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthCubit ve ThemeCubit tekil (LazySingleton): router ile aynı instance.
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AuthCubit>.value(value: sl<AuthCubit>()),
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (BuildContext context, ThemeMode themeMode) {
          return MaterialApp.router(
            title: 'EduPulse',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}