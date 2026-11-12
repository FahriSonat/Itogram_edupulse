import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/brand/edupulse_logo.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Uygulama açılış ekranı (Splash Screen).
/// 
/// Uygulama ilk açıldığında ekranda logonun ve yükleme göstergesinin belirdiği yerdir.
/// Bu ekranda mevcut bir Firebase Auth oturumu veya yerel önbellek kimliği kontrol edilir.
/// Kontrol sonucuna göre [RoleGuard] mekanizması kullanıcıyı otomatik olarak:
/// - Giriş yapılmışsa ve rolü belliyse: Ana sayfaya (`/home`)
/// - Oturum yoksa veya geçersizse: Giriş sayfasına (`/login`) yönlendirir.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Sayfa DOM ağacına yerleştiğinde oturum durumu ilk kez kontrol edilir.
    final cubit = context.read<AuthCubit>();
    if (cubit.state is AuthInitial) {
      cubit.checkAuthStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EduPulse marka logosu (küçük ekranlarda taşmayı önlemek için FittedBox ile sarılıdır)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.p24),
                child: FittedBox(fit: BoxFit.scaleDown, child: EduPulseLogo(size: 56)),
              ),
              const SizedBox(height: AppDimensions.p32),

              // Oturum doğrulama devam ederken gösterilen dairesel ilerleme çubuğu
              const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: AppDimensions.p16),

              // Kullanıcıyı bilgilendiren durum metni
              Text('Oturum kontrol ediliyor...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
