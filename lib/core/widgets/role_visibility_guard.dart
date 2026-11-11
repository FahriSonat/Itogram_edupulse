import 'package:flutter/material.dart';

import '../enums/user_role.dart';

/// [RoleVisibilityGuard] — Kritik İş Kuralı 5 (Arayüz Blokajı).
///
/// Aynı ekranda hem öğrenci hem eğitmen görünümü olduğunda [studentBuilder]
/// ve [instructorBuilder] parametrelerini alır; giriş yapan kullanıcının
/// [currentRole]'üne göre yalnızca ilgili widget ağacını çizer. Yetkisiz
/// rolün builder'ı hiç çağrılmaz; bu nedenle yetkisiz butonlar widget
/// ağacından tamamen kaldırılmış olur (gizlenmez, hiç oluşturulmaz).
///
/// Not: Bu yalnızca arayüz katmanıdır. Veritabanı seviyesindeki asıl blokaj
/// `firestore.rules` tarafından yapılır (çift katmanlı güvenlik).
class RoleVisibilityGuard extends StatelessWidget {
  const RoleVisibilityGuard({
    super.key,
    required this.currentRole,
    this.studentBuilder,
    this.instructorBuilder,
    this.fallback,
  });

  /// Yalnızca [UserRole.instructor] için [child] çizer (ör. not girişi, yoklama başlat).
  factory RoleVisibilityGuard.onlyInstructor({
    Key? key,
    required UserRole currentRole,
    required Widget child,
    Widget fallback = const SizedBox.shrink(),
  }) {
    return RoleVisibilityGuard(key: key, currentRole: currentRole, instructorBuilder: (_) => child, fallback: fallback);
  }

  /// Yalnızca [UserRole.student] için [child] çizer (ör. ödev yükle, PIN gir).
  factory RoleVisibilityGuard.onlyStudent({
    Key? key,
    required UserRole currentRole,
    required Widget child,
    Widget fallback = const SizedBox.shrink(),
  }) {
    return RoleVisibilityGuard(key: key, currentRole: currentRole, studentBuilder: (_) => child, fallback: fallback);
  }

  final UserRole currentRole;
  final WidgetBuilder? studentBuilder;
  final WidgetBuilder? instructorBuilder;

  /// İlgili rol için builder verilmemişse çizilir (varsayılan: boş alan).
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final builder = switch (currentRole) {
      UserRole.student => studentBuilder,
      UserRole.instructor => instructorBuilder,
    };
    return builder?.call(context) ?? fallback ?? const SizedBox.shrink();
  }
}
