import 'package:equatable/equatable.dart';

import '../../../../core/enums/user_role.dart';

/// [UserEntity] oturum açmış kullanıcı (öğrenci veya eğitmen).
class UserEntity extends Equatable {
  final String uid;
  final String fullName;
  final String email;

  /// Öğrenciler için öğrenci numarası, eğitmenler için sicil numarası.
  final String schoolNo;
  final UserRole role;
  final String department;

  const UserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.schoolNo,
    required this.role,
    this.department = '',
  });

  bool get isStudent => role.isStudent;
  bool get isInstructor => role.isInstructor;

  /// Karşılama metni için ilk isim ("Ayberk"). Eğitmenlerde tam ad kullanılır.
  String get greetingName => role.isStudent ? fullName.split(' ').first : fullName;

  /// Yan menüde isim altındaki bilgi satırı.
  String get subtitle => role.isStudent ? '$schoolNo • $department' : department;

  @override
  List<Object?> get props => [uid, fullName, email, schoolNo, role, department];
}
