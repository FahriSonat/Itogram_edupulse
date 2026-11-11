enum UserRole {
  student,
  instructor,
  admin,
}

extension UserRoleX on UserRole {
  /// Firestore'a yazılan string değer.
  String toJson() => name;

  bool get isInstructor => this == UserRole.instructor;
  bool get isStudent => this == UserRole.student;
  bool get isAdmin => this == UserRole.admin;

  /// Ekranda gösterilecek rozet metni (CustomAppBar).
  String get badgeLabel {
    switch (this) {
      case UserRole.student:
        return 'ÖĞRENCİ PORTALI';
      case UserRole.instructor:
        return 'EĞİTMEN YÖNETİM PANELİ';
      case UserRole.admin:
        return 'YÖNETİCİ PANELİ';
    }
  }

  static UserRole fromJson(String? value) {
    return UserRole.values.firstWhere(
      (UserRole role) => role.name == value,
      orElse: () => UserRole.student, // bilinmeyen değerde en düşük yetki
    );
  }
}
