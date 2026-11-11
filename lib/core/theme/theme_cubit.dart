import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/local_storage_service.dart';

/// [ThemeCubit] kullanıcının Açık / Koyu tema tercihini anlık değiştirir ve
/// [LocalStorageService] ile kalıcı hale getirir.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._storage) : super(ThemeMode.light) {
    loadSavedTheme();
  }

  final LocalStorageService _storage;

  /// [LocalStorageService]'te kayıtlı tema tercihini okuyup uygular.
  Future<void> loadSavedTheme() async {
    try {
      final raw = await _storage.getThemeMode(defaultMode: 'light');
      if (isClosed) return;
      emit(_parseThemeMode(raw));
    } catch (_) {
      // Depolama okunamazsa varsayılan açık tema korunur.
    }
  }

  static ThemeMode _parseThemeMode(String raw) => switch (raw) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };

  static String _serializeThemeMode(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
  };

  /// Aktif mod koyu tema mı?
  bool get isDarkMode => state == ThemeMode.dark;

  /// [ThemeMode.light] ↔ [ThemeMode.dark] arasında geçiş yapar.
  Future<void> toggleTheme() => setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);

  /// Belirli bir [ThemeMode] uygular ve kalıcı olarak kaydeder.
  Future<void> setTheme(ThemeMode mode) async {
    if (isClosed) return;
    emit(mode);
    try {
      await _storage.saveThemeMode(_serializeThemeMode(mode));
    } catch (_) {
      // Kayıt başarısız olsa da seçilen tema oturum boyunca geçerli kalır.
    }
  }
}
