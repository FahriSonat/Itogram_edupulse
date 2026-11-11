import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/role_selection_toggle.dart';

/// KAYIT OL EKRANI: Öğrenci No, Ad-Soyad, E-posta, Şifre (2 kez) ve
/// Öğrenci / Öğretmen Rol Belirleme Aşaması.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _studentNoController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _studentNoController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthCubit>().register(
          studentNo: _studentNoController.text,
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmController.text,
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
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
            final isLoading = state is AuthLoading;
            return SingleChildScrollView(
              padding: AppDimensions.paddingAll24,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('EduPulse hesabını oluştur', style: theme.textTheme.titleLarge),
                        const SizedBox(height: AppDimensions.p20),
                        AuthTextField(
                          key: const Key('register_student_no'),
                          controller: _studentNoController,
                          label: AppStrings.studentNoLabel,
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [StudentNoInputFormatter()],
                          validator: Validators.studentNo,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppDimensions.p12),
                        AuthTextField(
                          key: const Key('register_full_name'),
                          controller: _fullNameController,
                          label: AppStrings.fullNameLabel,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) => Validators.required(v, fieldName: AppStrings.fullNameLabel),
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppDimensions.p12),
                        AuthTextField(
                          key: const Key('register_email'),
                          controller: _emailController,
                          label: AppStrings.emailLabel,
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppDimensions.p12),
                        AuthTextField(
                          key: const Key('register_password'),
                          controller: _passwordController,
                          label: AppStrings.passwordLabel,
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: Validators.password,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppDimensions.p12),
                        AuthTextField(
                          key: const Key('register_confirm'),
                          controller: _confirmController,
                          label: AppStrings.passwordConfirmLabel,
                          prefixIcon: Icons.lock_reset_rounded,
                          isPassword: true,
                          validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppDimensions.p24),
                        Text('Rol Belirleme', style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppDimensions.p8),
                        RoleSelectionToggle(
                          selectedRole: _role,
                          onRoleChanged: (role) => setState(() => _role = role),
                        ),
                        const SizedBox(height: AppDimensions.p24),
                        FilledButton(
                          key: const Key('register_submit'),
                          onPressed: isLoading ? null : _submit,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          child: isLoading
                              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                              : const Text('Kayıt Ol'),
                        ),
                        const SizedBox(height: AppDimensions.p8),
                        TextButton(
                          onPressed: isLoading ? null : () => Navigator.maybePop(context),
                          child: const Text('Zaten hesabım var — Giriş Yap'),
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
