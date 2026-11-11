import '../../../../core/enums/user_role.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.schoolNo,
    required super.role,
    super.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['id'] as String,
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    schoolNo: json['schoolNo'] as String? ?? '',
    role: UserRole.fromJson(json['role'] as String?),
    department: json['department'] as String? ?? '',
  );

  /// Şifre güvenlik gereği modelde tutulmaz; datasource ayrıca ekler.
  Map<String, dynamic> toJson() => {
    'id': uid,
    'fullName': fullName,
    'email': email,
    'schoolNo': schoolNo,
    'role': role.toJson(),
    'department': department,
  };
}
