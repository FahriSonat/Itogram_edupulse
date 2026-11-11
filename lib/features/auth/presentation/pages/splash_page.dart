import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/brand/edupulse_logo.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Uygulama açılış ekranı. Oturum kontrolünü başlatır; sonuca göre
/// RoleGuard kullanıcıyı `/home` veya `/login` ekranına yönlendirir.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<AuthCubit>();
    if (cubit.state is AuthInitial) cubit.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.p24),
                child: FittedBox(fit: BoxFit.scaleDown, child: EduPulseLogo(size: 56)),
              ),
              const SizedBox(height: AppDimensions.p32),
              const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: AppDimensions.p16),
              Text('Oturum kontrol ediliyor...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
