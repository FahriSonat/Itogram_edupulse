import 'package:edupulse/core/config/flavor_config.dart';
import 'package:edupulse/core/di/injection_container.dart';
import 'package:edupulse/core/router/app_router.dart';
import 'package:edupulse/core/theme/app_theme.dart';
import 'package:edupulse/core/theme/theme_cubit.dart';
import 'package:edupulse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            debugShowCheckedModeBanner: FlavorConfig.showBanner,
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
