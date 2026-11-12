import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand/edupulse_logo.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_text_field.dart';

/// GİRİŞ YAP EKRANI (Login Page).
/// 
/// Kullanıcının Öğrenci Numarası / Sicil Numarası ve Şifresi ile sisteme giriş yaptığı sayfadır.
/// - Form doğrulaması [Validators.studentNo] ve [Validators.required] ile yapılır.
/// - Öğrenci numarası girişi [StudentNoInputFormatter] ile filtrelenir.
/// - Başarılı girişte GoRouter ve RoleGuard kullanıcıyı ana sayfaya yönlendirir.
/// - Hata durumlarında kullanıcıya SnackBar ile bilgi verilir.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Form durumunu ve doğrulamalarını yönetmek için kullanılan global anahtar
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Öğrenci no ve şifre metin kontrolcüleri
  final TextEditingController _studentNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // Sayfa kapandığında bellek sızıntısını önlemek için kontrolcüler dispose edilir
    _studentNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Form verilerini doğrulayıp AuthCubit üzerinden giriş işlemini tetikler.
  void _submit() {
    // Açık olan klavyeyi kapatıyoruz
    FocusScope.of(context).unfocus();

    // Form alanları kurallara uygun değilse işlemi durdur
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Cubit üzerinden Firebase/backend kimlik doğrulama çağrısı yapılır
    context.read<AuthCubit>().login(
          studentNo: _studentNoController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          // Hata durumunda SnackBar gösterimini tetikleyen dinleyici
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            // Yükleme sırasında butonları ve alanları devre dışı bırakmak için durum kontrolü
            final isLoading = state is AuthLoading;

            return Center(
              child: SingleChildScrollView(
                padding: AppDimensions.paddingAll24,
                // Tablet ve web gibi geniş ekranlarda formun aşırı genişlemesini önler
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // EduPulse Marka Logosu
                        const Center(child: FittedBox(fit: BoxFit.scaleDown, child: EduPulseLogo(size: 48))),
                        const SizedBox(height: AppDimensions.p32),

                        // Başlık ve Yönerge Metinleri
                        Text('Giriş Yap', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppDimensions.p4),
                        Text('Öğrenci / sicil numaran ve şifrenle devam et.', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: AppDimensions.p24),

                        // Öğrenci No / Sicil No Giriş Alanı
                        AuthTextField(
                          key: const Key('login_student_no'),
                          controller: _studentNoController,
                          label: AppStrings.studentNoLabel,
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [StudentNoInputFormatter()],
                          validator: Validators.studentNo,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppDimensions.p16),

                        // Şifre Giriş Alanı
                        AuthTextField(
                          key: const Key('login_password'),
                          controller: _passwordController,
                          label: AppStrings.passwordLabel,
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: (v) => Validators.required(v, fieldName: AppStrings.passwordLabel),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          enabled: !isLoading,
                        ),

                        // Şifremi Unuttum Bağlantı Butonu
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading ? null : () => context.push(RouteNames.forgotPassword),
                            child: const Text('Şifremi Unuttum'),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.p8),

                        // Giriş Yap Butonu (Yüklenirken spinner gösterir)
                        FilledButton(
                          key: const Key('login_submit'),
                          onPressed: isLoading ? null : _submit,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          child: isLoading
                              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                              : const Text('Giriş Yap'),
                        ),
                        const SizedBox(height: AppDimensions.p16),

                        // Kayıt Ol Yönlendirmesi
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Hesabın yok mu?'),
                            TextButton(
                              onPressed: isLoading ? null : () => context.push(RouteNames.register),
                              child: const Text('Kayıt Ol'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
