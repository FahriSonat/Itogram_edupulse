import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_text_field.dart';

/// ŞİFREMİ UNUTTUM EKRANI: kayıtlı e-postaya Firebase şifre sıfırlama maili.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthCubit>().sendPasswordReset(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is PasswordResetSent) {
              return _SentView(email: state.email);
            }
            final isLoading = state is AuthLoading;
            return SingleChildScrollView(
              padding: AppDimensions.paddingAll24,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_unread_outlined, size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: AppDimensions.p16),
                    Text(
                      'Kayıtlı e-posta adresini gir; şifre sıfırlama bağlantısını gönderelim.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.p24),
                    AuthTextField(
                      key: const Key('forgot_email'),
                      controller: _emailController,
                      label: AppStrings.emailLabel,
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppDimensions.p24),
                    FilledButton(
                      key: const Key('forgot_submit'),
                      onPressed: isLoading ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: isLoading
                          ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Text('Sıfırlama Bağlantısı Gönder'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SentView extends StatelessWidget {
  const _SentView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: AppDimensions.paddingAll24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.resolvedGreen),
            const SizedBox(height: AppDimensions.p16),
            Text('Bağlantı gönderildi', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.p8),
            Text(
              '$email adresine şifre sıfırlama bağlantısı gönderildi. Gelen kutunu (ve spam klasörünü) kontrol et.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.p24),
            OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Giriş ekranına dön'),
            ),
          ],
        ),
      ),
    );
  }
}
