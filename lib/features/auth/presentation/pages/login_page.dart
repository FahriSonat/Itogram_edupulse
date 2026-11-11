import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/flavor_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/demo_seed_data.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/animations/fade_slide_in.dart';
import '../../../../core/widgets/atmosphere/ambient_background.dart';
import '../../../../core/widgets/brand/edupulse_logo.dart';
import '../../../../core/widgets/edu_card.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/role_selection_toggle.dart';

/// [LoginPage] öğrenci / sicil numarası veya kurumsal e-posta ile giriş ekranı.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
      identifier: _identifierController.text,
      password: _passwordController.text,
      expectedRole: _role,
    );
  }

  void _fillDemo(UserRole role) {
    setState(() {
      _role = role;
      _identifierController.text = role.isStudent ? '202604001' : '1001';
      _passwordController.text = DemoSeedData.demoPassword;
    });
  }

  Future<void> _resetDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demo verilerini sıfırla'),
        content: const Text(
          'Cihazdaki tüm EduPulse verileri (dersler, ödevler, notlar, forum, yoklamalar ve yeni kayıtlı hesaplar) '
          'silinip başlangıç demo verisi yeniden yüklenecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sıfırla')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await sl<LocalStorageService>().resetDemoData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo verileri yeniden yüklendi.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return BlocListener<AuthCubit, AuthState>(
      // Kayıt sayfası üstteyken hata mesajını o sayfa gösterir.
      listenWhen: (prev, curr) =>
          curr.errorMessage != null &&
          prev.errorMessage != curr.errorMessage &&
          (ModalRoute.of(context)?.isCurrent ?? true),
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.criticalAbsenceRed));
      },
      child: AmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppDimensions.paddingAll24,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: EduPulseLogo(size: 44)),
                        const SizedBox(height: AppDimensions.p24),
                        FadeSlideIn(
                          child: Text(
                            'Tekrar hoş geldin!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.p6),
                        Text(
                          'Portalını seç ve hesabınla giriş yap.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                        ),
                        const SizedBox(height: AppDimensions.p24),
                        RoleSelectionToggle(selectedRole: _role, onRoleChanged: (r) => setState(() => _role = r)),
                        const SizedBox(height: AppDimensions.p20),
                        AuthTextField(
                          controller: _identifierController,
                          label: _role.isStudent ? 'Öğrenci Numarası veya E-posta' : 'Sicil Numarası veya E-posta',
                          hint: _role.isStudent ? '202604001' : '1001',
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.loginIdentifier,
                        ),
                        const SizedBox(height: AppDimensions.p16),
                        AuthTextField(
                          controller: _passwordController,
                          label: AppStrings.passwordLabel,
                          hint: '••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: Validators.password,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(RouteNames.forgotPassword),
                            child: const Text('Şifremi unuttum'),
                          ),
                        ),
                        BlocBuilder<AuthCubit, AuthState>(
                          buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
                          builder: (context, state) => ElevatedButton(
                            onPressed: state.isSubmitting ? null : _submit,
                            child: state.isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text('Giriş Yap'),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.p12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Hesabın yok mu?', style: TextStyle(color: muted)),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushNamed(RouteNames.register),
                              child: const Text('Kayıt Ol'),
                            ),
                          ],
                        ),
                        if (FlavorConfig.current.showDemoAccounts) ...[
                          const SizedBox(height: AppDimensions.p12),
                          _DemoAccountsCard(onPick: _fillDemo, onReset: _resetDemoData),
                        ],
                      ],
                    ),
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

class _DemoAccountsCard extends StatelessWidget {
  const _DemoAccountsCard({required this.onPick, required this.onReset});

  final ValueChanged<UserRole> onPick;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return EduCard(
      padding: AppDimensions.paddingAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 18, color: muted),
              const SizedBox(width: 6),
              Text('Demo hesaplar', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tüm demo hesaplarının şifresi: ${DemoSeedData.demoPassword}. Doldurmak için dokunun.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: AppDimensions.p12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.school_rounded, size: 16),
                label: const Text('Öğrenci • 202604001'),
                onPressed: () => onPick(UserRole.student),
              ),
              ActionChip(
                avatar: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                label: const Text('Eğitmen • 1001'),
                onPressed: () => onPick(UserRole.instructor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Demo verilerini sıfırla'),
            ),
          ),
        ],
      ),
    );
  }
}
