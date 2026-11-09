import '../../domain/entities/user_entity.dart';
import '../../../../core/enums/user_role.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.studentOrStaffNo,
    required super.fullName,
    required super.email,
    required super.role,
    super.fcmToken,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      studentOrStaffNo: json['studentOrStaffNo'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      fcmToken: json['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentOrStaffNo': studentOrStaffNo,
      'fullName': fullName,
      'email': email,
      'role': role.name,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? uid,
    String? studentOrStaffNo,
    String? fullName,
    String? email,
    UserRole? role,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      studentOrStaffNo: studentOrStaffNo ?? this.studentOrStaffNo,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}