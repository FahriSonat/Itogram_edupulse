// Geliştirici 6 — Auth sayfaları: Form / Regex validasyonları, rol seçimi,
// yükleme ve hata durumları (GlobalKey<FormState> + dispose kurallı ekranlar).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_state.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/login_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/register_page.dart';
import 'package:itogram_edupulse/features/auth/presentation/pages/splash_page.dart';

import '../../helpers/page_harness.dart';

Finder _field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText));

void main() {
  late TestBackend backend;

  setUp(() async {
    backend = TestBackend();
    await backend.register();
  });

  group('SplashPage', () {
    testWidgets('açılışta oturum kontrolünü başlatır', (tester) async {
      final auth = await pumpPage(tester, const SplashPage(), backend: backend, role: null);
      expect(backend.auth.calls, contains('current'));
      expect(auth.state, const Unauthenticated());
    });
  });

  group('LoginPage (GİRİŞ YAP)', () {
    testWidgets('boş formda doğrulama mesajları gösterilir ve depoya gidilmez', (tester) async {
      await pumpPage(tester, const LoginPage(), backend: backend, role: null);
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();

      expect(find.text('Öğrenci numarası boş bırakılamaz'), findsOneWidget);
      expect(find.text('${AppStrings.passwordLabel} boş bırakılamaz'), findsOneWidget);
      expect(backend.auth.calls.where((c) => c.startsWith('login')), isEmpty);
    });

    testWidgets('öğrenci numarası alanı yalnızca rakam kabul eder', (tester) async {
      await pumpPage(tester, const LoginPage(), backend: backend, role: null);
      await tester.enterText(_field('login_student_no'), '20ab26x1');
      expect(tester.widget<EditableText>(_field('login_student_no')).controller.text, '20261');
    });

    testWidgets('kısa öğrenci numarası reddedilir', (tester) async {
      await pumpPage(tester, const LoginPage(), backend: backend, role: null);
      await tester.enterText(_field('login_student_no'), '123');
      await tester.enterText(_field('login_password'), 'Sifre123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();
      expect(find.textContaining('haneli olmalıdır'), findsOneWidget);
    });

    testWidgets('geçerli bilgilerle AuthCubit.login çağrılır ve oturum açılır', (tester) async {
      final auth = await pumpPage(tester, const LoginPage(), backend: backend, role: null);
      await tester.enterText(_field('login_student_no'), '20261234');
      await tester.enterText(_field('login_password'), 'Sifre123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await settle(tester);

      expect(backend.auth.calls, contains('login:20261234'));
      expect(auth.state, isA<Authenticated>());
    });

    testWidgets('hatalı girişte SnackBar ile Türkçe hata gösterilir', (tester) async {
      backend.auth.error = Exception('Öğrenci numarası veya şifre hatalı.');
      await pumpPage(tester, const LoginPage(), backend: backend, role: null);
      await tester.enterText(_field('login_student_no'), '20261234');
      await tester.enterText(_field('login_password'), 'yanlis');
      await tester.tap(find.byKey(const Key('login_submit')));
      await settle(tester);

      expect(find.textContaining('Öğrenci numarası veya şifre hatalı.'), findsOneWidget);
    });
  });

  group('RegisterPage (KAYIT OL + Rol Belirleme)', () {
    Future<void> fill(WidgetTester tester, {String password = 'Sifre123', String confirm = 'Sifre123'}) async {
      await tester.enterText(_field('register_student_no'), '20269999');
      await tester.enterText(_field('register_full_name'), 'Ahmet Eroğlu');
      await tester.enterText(_field('register_email'), 'ahmet@edupulse.edu.tr');
      await tester.enterText(_field('register_password'), password);
      await tester.enterText(_field('register_confirm'), confirm);
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('register_submit')));
      await tester.tap(find.byKey(const Key('register_submit')));
      await settle(tester);
    }

    testWidgets('şifreler eşleşmezse kayıt yapılmaz', (tester) async {
      await pumpPage(tester, const RegisterPage(), backend: backend, role: null);
      await fill(tester, confirm: 'Sifre124');
      await submit(tester);

      expect(find.text('Şifreler eşleşmiyor'), findsOneWidget);
      expect(backend.auth.lastRegister, isNull);
    });

    testWidgets('zayıf şifre (büyük harf / rakam yok) reddedilir', (tester) async {
      await pumpPage(tester, const RegisterPage(), backend: backend, role: null);
      await fill(tester, password: 'sifresifre', confirm: 'sifresifre');
      await submit(tester);

      expect(find.text('Şifre en az bir büyük harf içermelidir'), findsOneWidget);
      expect(backend.auth.lastRegister, isNull);
    });

    testWidgets('geçersiz e-posta reddedilir', (tester) async {
      await pumpPage(tester, const RegisterPage(), backend: backend, role: null);
      await fill(tester);
      await tester.enterText(_field('register_email'), 'ahmet@');
      await submit(tester);
      expect(find.text('Geçerli bir e-posta adresi giriniz'), findsOneWidget);
    });

    testWidgets('varsayılan rol öğrencidir', (tester) async {
      await pumpPage(tester, const RegisterPage(), backend: backend, role: null);
      await fill(tester);
      await submit(tester);
      expect(backend.auth.lastRegister?['role'], UserRole.student);
    });

    testWidgets('Eğitmen rolü seçilirse kayıt eğitmen olarak yapılır', (tester) async {
      final auth = await pumpPage(tester, const RegisterPage(), backend: backend, role: null);
      await fill(tester);
      await tester.ensureVisible(find.text(AppStrings.instructorRole));
      await tester.tap(find.text(AppStrings.instructorRole));
      await tester.pump();
      await submit(tester);

      expect(backend.auth.lastRegister?['role'], UserRole.instructor);
      expect(auth.state.isInstructor, isTrue);
    });
  });

  group('ForgotPasswordPage (ŞİFREMİ UNUTTUM)', () {
    testWidgets('geçersiz e-posta reddedilir', (tester) async {
      await pumpPage(tester, const ForgotPasswordPage(), backend: backend, role: null);
      await tester.enterText(_field('forgot_email'), 'merve-at-mail');
      await tester.tap(find.byKey(const Key('forgot_submit')));
      await tester.pump();
      expect(find.text('Geçerli bir e-posta adresi giriniz'), findsOneWidget);
      expect(backend.auth.calls, isEmpty);
    });

    testWidgets('geçerli e-postada bağlantı gönderilir ve onay ekranı açılır', (tester) async {
      await pumpPage(tester, const ForgotPasswordPage(), backend: backend, role: null);
      await tester.enterText(_field('forgot_email'), 'merve@edupulse.edu.tr');
      await tester.tap(find.byKey(const Key('forgot_submit')));
      await settle(tester);

      expect(backend.auth.calls, contains('reset:merve@edupulse.edu.tr'));
      expect(find.text('Bağlantı gönderildi'), findsOneWidget);
    });
  });
}
