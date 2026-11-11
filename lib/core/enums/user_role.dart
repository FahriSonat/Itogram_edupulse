/// Represents the dual-role architecture for EduPulse:
/// [UserRole.student] (Öğrenci Portalı) and [UserRole.instructor] (Eğitmen Yönetim Paneli).
enum UserRole {
  student,
  instructor;

  String toJson() => name;

  static UserRole fromJson(String? value) {
    if (value == null) return UserRole.student;
    return UserRole.values.firstWhere(
      (role) => role.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.student,
    );
  }

  bool get isStudent => this == UserRole.student;
  bool get isInstructor => this == UserRole.instructor;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Öğrenci';
      case UserRole.instructor:
        return 'Eğitmen';
    }
  }

  String get portalBadgeText {
    switch (this) {
      case UserRole.student:
        return 'ÖĞRENCİ PORTALI';
      case UserRole.instructor:
        return 'EĞİTMEN YÖNETİM PANELİ';
    }
  }
}
