import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/local_storage_service.dart';

/// Oturum açan kullanıcının rolünü ve temel profilini hızlı başlangıç için
/// yerel önbelleğe kaydeder ve çıkışta temizler.
abstract class AuthLocalDataSource {
  Future<void> cacheUser(Map<String, dynamic> userJson);
  Future<Map<String, dynamic>?> getLastCachedUser();
  Future<void> cacheUserRole(String role);
  Future<String?> getCachedUserRole();
  Future<void> cacheAuthToken(String token);
  Future<String?> getCachedAuthToken();
  Future<void> clearAuthCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStorageService _localStorageService;

  AuthLocalDataSourceImpl({
    LocalStorageService? localStorageService,
    SharedPreferences? sharedPreferences,
  }) : _localStorageService =
            localStorageService ?? LocalStorageService(sharedPreferences);

  @override
  Future<void> cacheUser(Map<String, dynamic> userJson) async {
    await _localStorageService.setJsonMap(
      LocalStorageService.keyCachedUser,
      userJson,
    );
    final role = userJson['role']?.toString();
    if (role != null && role.isNotEmpty) {
      await cacheUserRole(role);
    }
  }

  @override
  Future<Map<String, dynamic>?> getLastCachedUser() async {
    return _localStorageService.getJsonMap(LocalStorageService.keyCachedUser);
  }

  @override
  Future<void> cacheUserRole(String role) async {
    await _localStorageService.saveLastSelectedRole(role);
  }

  @override
  Future<String?> getCachedUserRole() async {
    return _localStorageService.getLastSelectedRole();
  }

  @override
  Future<void> cacheAuthToken(String token) async {
    await _localStorageService.saveAuthToken(token);
  }

  @override
  Future<String?> getCachedAuthToken() async {
    return _localStorageService.getAuthToken();
  }

  @override
  Future<void> clearAuthCache() async {
    await _localStorageService.remove(LocalStorageService.keyCachedUser);
    await _localStorageService.remove(LocalStorageService.keyAuthToken);
    await _localStorageService.remove(LocalStorageService.keyUserRole);
  }
}
