import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/atmosphere/ambient_background.dart';
import '../../../../core/widgets/edu_card.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_text_field.dart';

/// [ForgotPasswordPage] kayıtlı e-posta için şifre sıfırlama talebi.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _sentTo;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final error = await context.read<AuthCubit>().sendPasswordReset(_emailController.text);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (error == null) _sentTo = _emailController.text.trim();
    });
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.criticalAbsenceRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Şifremi Unuttum'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppDimensions.paddingAll24,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _sentTo != null
                    ? EduCard(
                        padding: AppDimensions.paddingAll24,
                        child: Column(
                          children: [
                            const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.resolvedGreen),
                            const SizedBox(height: AppDimensions.p16),
                            Text(
                              'Talebiniz alındı',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: AppDimensions.p8),
                            Text(
                              '$_sentTo adresine kayıtlı hesap doğrulandı. Gerçek sunucuya bağlandığında '
                              'şifre sıfırlama bağlantısı bu adrese gönderilir.\n\n'
                              'Not: Bu sürüm verileri cihazda tuttuğu için e-posta gönderimi yapılmaz.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                            ),
                            const SizedBox(height: AppDimensions.p20),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Girişe Dön'),
                            ),
                          ],
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(Icons.lock_reset_rounded, size: 56, color: theme.colorScheme.primary),
                            const SizedBox(height: AppDimensions.p16),
                            Text(
                              'Kurumsal e-posta adresinizi girin; hesabınız doğrulanıp sıfırlama talebi oluşturulur.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                            ),
                            const SizedBox(height: AppDimensions.p24),
                            AuthTextField(
                              controller: _emailController,
                              label: AppStrings.emailLabel,
                              hint: 'ad.soyad@edupulse.edu.tr',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: AppDimensions.p24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: Text(_isLoading ? 'Kontrol ediliyor...' : 'Sıfırlama Talebi Gönder'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
