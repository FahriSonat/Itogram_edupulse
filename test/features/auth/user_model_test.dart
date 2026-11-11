import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/auth/data/models/user_model.dart';
import 'package:itogram_edupulse/features/auth/domain/entities/user_entity.dart';

void main() {
  const UserModel model = UserModel(
    uid: 'uid-1',
    studentOrStaffNo: '20261234',
    fullName: 'Merve Kedersiz',
    email: 'merve@softito.com',
    role: UserRole.instructor,
    fcmToken: 'token-abc',
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'studentOrStaffNo': '20261234',
    'fullName': 'Merve Kedersiz',
    'email': 'merve@softito.com',
    'role': 'instructor',
    'fcmToken': 'token-abc',
  };

  group('UserModel', () {
    test('UserEntity alt sınıfıdır', () {
      expect(model, isA<UserEntity>());
    });

    test('fromFirestore tüm alanları doğru okur', () {
      expect(UserModel.fromFirestore(json, 'uid-1'), model);
    });

    test('toJson doğru map üretir (uid dökümana yazılmaz)', () {
      expect(model.toJson(), json);
      expect(model.toJson().containsKey('uid'), isFalse);
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(UserModel.fromFirestore(model.toJson(), model.uid), model);
    });

    test('rol string olarak yazılır ve okunur', () {
      for (final UserRole role in UserRole.values) {
        final UserModel m = model.copyWith(role: role);
        expect(m.toJson()['role'], role.name);
        expect(UserModel.fromFirestore(m.toJson(), m.uid).role, role);
      }
    });

    test('bilinmeyen rol güvenli şekilde student olur', () {
      final Map<String, dynamic> bad = Map<String, dynamic>.of(json)
        ..['role'] = 'hacker';
      expect(UserModel.fromFirestore(bad, 'uid-1').role, UserRole.student);
    });

    test('fcmToken yoksa null olur', () {
      final Map<String, dynamic> noToken = Map<String, dynamic>.of(json)
        ..remove('fcmToken');
      expect(UserModel.fromFirestore(noToken, 'uid-1').fcmToken, isNull);
    });

    test('copyWith sadece verilen alanı değiştirir', () {
      final UserModel updated = model.copyWith(fullName: 'Yeni İsim');
      expect(updated.fullName, 'Yeni İsim');
      expect(updated.copyWith(fullName: model.fullName), model);
    });

    test('copyWith parametresiz çağrılınca eşit nesne döner', () {
      expect(model.copyWith(), model);
    });
  });
}
