import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/atmosphere/ambient_background.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/role_selection_toggle.dart';

/// [RegisterPage] yeni öğrenci veya eğitmen hesabı oluşturma ekranı.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _noController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _noController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().register(
      fullName: _nameController.text,
      email: _emailController.text,
      schoolNo: _noController.text,
      password: _passwordController.text,
      role: _role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          // Kayıt başarılı: kök ekran ana panele geçer, bu sayfa kapanır.
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.criticalAbsenceRed));
        }
      },
      child: AmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Hesap Oluştur'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppDimensions.paddingAll24,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'EduPulse\'a katıl',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text('Rolünü seç, bilgilerini gir ve hemen kampüse bağlan.', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: AppDimensions.p20),
                        RoleSelectionToggle(selectedRole: _role, onRoleChanged: (r) => setState(() => _role = r)),
                        const SizedBox(height: AppDimensions.p20),
                        AuthTextField(
                          controller: _nameController,
                          label: AppStrings.fullNameLabel,
                          hint: 'Ad Soyad',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: Validators.fullName,
                        ),
                        const SizedBox(height: AppDimensions.p16),
                        AuthTextField(
                          controller: _emailController,
                          label: AppStrings.emailLabel,
                          hint: 'ad.soyad@edupulse.edu.tr',
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: AppDimensions.p16),
                        AuthTextField(
                          controller: _noController,
                          label: _role.isStudent ? 'Öğrenci Numarası' : 'Sicil Numarası',
                          hint: _role.isStudent ? '202604010' : '1010',
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: AppInputFormatters.studentNo,
                          validator: Validators.studentNo,
                        ),
                        const SizedBox(height: AppDimensions.p16),
                        AuthTextField(
                          controller: _passwordController,
                          label: AppStrings.passwordLabel,
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: AppDimensions.p16),
                        AuthTextField(
                          controller: _confirmController,
                          label: AppStrings.passwordConfirmLabel,
                          prefixIcon: Icons.lock_reset_rounded,
                          isPassword: true,
                          validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                        ),
                        const SizedBox(height: AppDimensions.p24),
                        BlocBuilder<AuthCubit, AuthState>(
                          buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
                          builder: (context, state) => ElevatedButton(
                            onPressed: state.isSubmitting ? null : _submit,
                            child: Text(state.isSubmitting ? 'Hesap oluşturuluyor...' : 'Hesap Oluştur'),
                          ),
                        ),
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
