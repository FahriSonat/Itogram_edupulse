import 'package:equatable/equatable.dart';
import '../../../../core/enums/user_role.dart';

class UserEntity extends Equatable {
  final String uid;
  final String studentOrStaffNo;
  final String fullName;
  final String email;
  final UserRole role;
  final String? fcmToken;

  const UserEntity({
    required this.uid,
    required this.studentOrStaffNo,
    required this.fullName,
    required this.email,
    required this.role,
    this.fcmToken,
  });

  @override
  List<Object?> get props => [
        uid,
        studentOrStaffNo,
        fullName,
        email,
        role,
        fcmToken,
      ];
}