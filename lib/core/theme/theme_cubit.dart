import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/local_storage_service.dart';

/// [ThemeCubit] kullanıcının Açık / Koyu tema tercihini anlık değiştirir ve
/// [LocalStorageService] ile kalıcı hale getirir.
///
/// Kayıtlı tercih kurucuda senkron okunur; böylece uygulama açılışında
/// yanlış temanın bir kare görünüp sonra değişmesi (flash) yaşanmaz.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._storage) : super(_readSaved(_storage));

  /// [LocalStorageService] içindeki tercih anahtarı (true = koyu tema).
  static const String themePrefKey = 'edupulse_theme_mode';

  final LocalStorageService _storage;

  static ThemeMode _readSaved(LocalStorageService storage) {
    try {
      final isDark = storage.getBool(themePrefKey);
      if (isDark == null) return ThemeMode.light;
      return isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // Depolama okunamazsa varsayılan açık tema ile devam edilir.
      return ThemeMode.light;
    }
  }

  /// Aktif mod koyu tema mı?
  bool get isDarkMode => state == ThemeMode.dark;

  /// [ThemeMode.light] ↔ [ThemeMode.dark] arasında geçiş yapar.
  Future<void> toggleTheme() => setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);

  /// Belirli bir [ThemeMode] uygular ve kalıcı olarak kaydeder.
  Future<void> setTheme(ThemeMode mode) async {
    if (isClosed) return;
    emit(mode);
    try {
      await _storage.setBool(themePrefKey, mode == ThemeMode.dark);
    } catch (_) {
      // Kayıt başarısız olsa da seçilen tema oturum boyunca geçerli kalır.
    }
  }
}
