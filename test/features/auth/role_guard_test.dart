// Kural 5 Testi (Mutlak Rol Güvenliği):
// Öğrenci rolündeki bir hesap not girişi ve yoklama başlatma bileşenlerini
// görememeli ve RoleGuard tarafından eğitmen sayfalarından engellenmelidir.
//
// BEKLEMEDE: lib/core/router/role_guard.dart (Geliştirici 1) ve
// lib/core/widgets/role_visibility_guard.dart (Geliştirici 2) henüz boş.
// Bu sınıflar yazılınca testler eklenecek.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'RoleGuard ve RoleVisibilityGuard (Kural 5)',
    () {},
    skip: 'BEKLEMEDE: role_guard.dart (Geliştirici 1) ve '
        'role_visibility_guard.dart (Geliştirici 2) boş. '
        'Kod yazılınca testler eklenecek.',
  );
}
