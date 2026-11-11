import '../../../../core/services/local_storage_service.dart';

/// [AuthLocalDataSource] oturum bilgisini ve onboarding durumunu cihazda saklar.
abstract class AuthLocalDataSource {
  String? getCachedUid();
  Future<void> cacheUid(String uid);
  Future<void> clearSession();
  bool hasSeenOnboarding();
  Future<void> markOnboardingSeen();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._storage);

  static const String _sessionKey = 'edupulse_session_uid';
  static const String _onboardingKey = 'edupulse_onboarding_seen';

  final LocalStorageService _storage;

  @override
  String? getCachedUid() => _storage.getString(_sessionKey);

  @override
  Future<void> cacheUid(String uid) => _storage.setString(_sessionKey, uid);

  @override
  Future<void> clearSession() => _storage.remove(_sessionKey);

  @override
  bool hasSeenOnboarding() => _storage.getBool(_onboardingKey) ?? false;

  @override
  Future<void> markOnboardingSeen() => _storage.setBool(_onboardingKey, true);
}
