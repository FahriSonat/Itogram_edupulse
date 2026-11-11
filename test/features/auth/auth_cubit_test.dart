// Geliştirici 5 (State & Logic) — Auth UseCase'leri ve AuthCubit testleri.
// AuthInitial → AuthLoading → Authenticated / AuthError / Unauthenticated /
// PasswordResetSent akışları ve isInstructor bilgisi.

import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/auth/domain/usecases/register_user_usecase.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:itogram_edupulse/features/auth/presentation/cubit/auth_state.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthCubit cubit;
  late List<AuthState> emitted;

  setUp(() {
    repository = FakeAuthRepository();
    cubit = buildAuthCubit(repository);
    emitted = <AuthState>[];
    cubit.stream.listen(emitted.add);
  });

  tearDown(() => cubit.close());

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('başlangıç durumu AuthInitial', () {
    expect(cubit.state, const AuthInitial());
    expect(cubit.state.isInstructor, isFalse);
  });

  group('checkAuthStatus (Splash)', () {
    test('aktif oturum varsa Authenticated(user)', () async {
      repository.currentUser = testStudent;
      await cubit.checkAuthStatus();
      expect(cubit.state, const Authenticated(testStudent));
    });

    test('oturum yoksa Unauthenticated', () async {
      await cubit.checkAuthStatus();
      expect(cubit.state, const Unauthenticated());
    });

    test('depo hata verirse uygulama çökmez, Unauthenticated olur', () async {
      repository.error = Exception('ağ yok');
      await cubit.checkAuthStatus();
      expect(cubit.state, const Unauthenticated());
    });
  });

  group('login', () {
    test('başarılı girişte AuthLoading → Authenticated', () async {
      await cubit.login(studentNo: ' 20261234 ', password: 'Sifre123!');
      await flush();

      expect(emitted, <AuthState>[const AuthLoading(), const Authenticated(testStudent)]);
      expect(repository.calls, contains('login:20261234'), reason: 'öğrenci no kırpılmalı');
    });

    test('eğitmen girişinde isInstructor true', () async {
      repository.loginResult = testInstructor;
      await cubit.login(studentNo: 'S-001', password: 'Sifre123!');
      expect(cubit.state.isInstructor, isTrue);
    });

    test('öğrenci girişinde isInstructor false', () async {
      await cubit.login(studentNo: '20261234', password: 'Sifre123!');
      expect(cubit.state, isA<Authenticated>());
      expect(cubit.state.isInstructor, isFalse);
    });

    test('hatalı şifrede AuthError ve depodaki mesaj taşınır', () async {
      repository.error = Exception('Şifre hatalı.');
      await cubit.login(studentNo: '20261234', password: 'yanlis');

      final state = cubit.state;
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, contains('Şifre hatalı.'));
    });

    test('boş alanlarla depoya hiç gidilmez', () async {
      await cubit.login(studentNo: '   ', password: '');
      expect(cubit.state, isA<AuthError>());
      expect(repository.calls, isEmpty);
    });
  });

  group('register', () {
    test('şifreler eşleşmezse depoya gidilmez ve hata verilir', () async {
      await cubit.register(
        studentNo: '20269999',
        fullName: 'Ahmet Eroğlu',
        email: 'ahmet@edupulse.edu.tr',
        password: 'Sifre123!',
        confirmPassword: 'Sifre124!',
        role: UserRole.student,
      );

      expect(cubit.state, const AuthError('Şifreler eşleşmiyor.'));
      expect(repository.calls, isEmpty);
    });

    test('seçilen rol (eğitmen) depoya iletilir ve oturum açılır', () async {
      await cubit.register(
        studentNo: ' S-777 ',
        fullName: ' Alaaddin Odabaşı ',
        email: ' alaaddin@edupulse.edu.tr ',
        password: 'Sifre123!',
        confirmPassword: 'Sifre123!',
        role: UserRole.instructor,
      );

      expect(repository.lastRegister, <String, Object?>{
        'studentNo': 'S-777',
        'fullName': 'Alaaddin Odabaşı',
        'email': 'alaaddin@edupulse.edu.tr',
        'role': UserRole.instructor,
      });
      expect(cubit.state, isA<Authenticated>());
      expect(cubit.state.isInstructor, isTrue);
    });

    test('RegisterUserUseCase doğrudan çağrıldığında da eşleşme kontrolü yapar', () async {
      final result = await RegisterUserUseCase(repository).call(
        studentNo: '1',
        fullName: 'a',
        email: 'a@b.c',
        password: 'x',
        confirmPassword: 'y',
        role: UserRole.student,
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('sendPasswordReset', () {
    test('başarılıysa PasswordResetSent(email)', () async {
      await cubit.sendPasswordReset(' merve@edupulse.edu.tr ');
      expect(cubit.state, const PasswordResetSent('merve@edupulse.edu.tr'));
      expect(repository.calls, <String>['reset:merve@edupulse.edu.tr']);
    });

    test('boş e-posta hata verir', () async {
      await cubit.sendPasswordReset('  ');
      expect(cubit.state, isA<AuthError>());
      expect(repository.calls, isEmpty);
    });

    test('Firebase hatası AuthError olur', () async {
      repository.error = Exception('Kullanıcı bulunamadı.');
      await cubit.sendPasswordReset('yok@edupulse.edu.tr');
      expect(cubit.state, isA<AuthError>());
    });
  });

  group('logout', () {
    test('çıkışta Unauthenticated olur ve depo temizlenir', () async {
      await cubit.login(studentNo: '20261234', password: 'Sifre123!');
      await cubit.logout();

      expect(cubit.state, const Unauthenticated());
      expect(repository.currentUser, isNull);
    });

    test('çıkış hata verse bile kullanıcı oturumdan çıkarılır', () async {
      await cubit.login(studentNo: '20261234', password: 'Sifre123!');
      repository.error = Exception('ağ yok');
      await cubit.logout();
      expect(cubit.state, const Unauthenticated());
    });
  });
}
