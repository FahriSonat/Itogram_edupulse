import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences kullanarak kullanıcı oturum token'ını, son seçilen rol bilgisini,
/// Açık/Koyu tema tercihini ve çevrimdışı ödev/soru taslaklarını saklar.
class LocalStorageService {
  SharedPreferences? _prefs;

  static const String keyCachedUser = 'cached_user_data';
  static const String keyAuthToken = 'cached_auth_token';
  static const String keyUserRole = 'cached_user_role';
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyFcmToken = 'cached_fcm_token';
  static const String keyAssignmentDraftPrefix = 'offline_assignment_draft_';
  static const String keyForumQuestionDraft = 'offline_forum_question_draft';

  LocalStorageService([this._prefs]);

  Future<SharedPreferences> get _instance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ===========================================================================
  // 1. Oturum Token ve Son Seçilen Rol Yönetimi
  // ===========================================================================
  Future<bool> saveAuthToken(String token) => setString(keyAuthToken, token);

  Future<String?> getAuthToken() => getString(keyAuthToken);

  Future<bool> saveLastSelectedRole(String role) => setString(keyUserRole, role);

  Future<String?> getLastSelectedRole() => getString(keyUserRole);

  // ===========================================================================
  // 2. Açık / Koyu Tema Tercihi Yönetimi ('light', 'dark', 'system')
  // ===========================================================================
  Future<bool> saveThemeMode(String themeMode) =>
      setString(keyThemeMode, themeMode);

  Future<String> getThemeMode({String defaultMode = 'system'}) async {
    return (await getString(keyThemeMode)) ?? defaultMode;
  }

  // ===========================================================================
  // 3. Çevrimdışı Ödev ve Forum Soru Taslakları (Offline Drafts)
  // ===========================================================================
  Future<bool> saveAssignmentDraft(
    String assignmentId,
    Map<String, dynamic> draftData,
  ) {
    return setJsonMap('$keyAssignmentDraftPrefix$assignmentId', draftData);
  }

  Future<Map<String, dynamic>?> getAssignmentDraft(String assignmentId) {
    return getJsonMap('$keyAssignmentDraftPrefix$assignmentId');
  }

  Future<bool> removeAssignmentDraft(String assignmentId) {
    return remove('$keyAssignmentDraftPrefix$assignmentId');
  }

  Future<bool> saveForumQuestionDraft(Map<String, dynamic> draftData) {
    return setJsonMap(keyForumQuestionDraft, draftData);
  }

  Future<Map<String, dynamic>?> getForumQuestionDraft() {
    return getJsonMap(keyForumQuestionDraft);
  }

  Future<bool> clearForumQuestionDraft() {
    return remove(keyForumQuestionDraft);
  }

  // ===========================================================================
  // Temel Anahtar-Değer Metodları
  // ===========================================================================
  Future<bool> setString(String key, String value) async {
    final prefs = await _instance;
    return prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _instance;
    return prefs.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    final prefs = await _instance;
    return prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _instance;
    return prefs.getBool(key);
  }

  Future<bool> setInt(String key, int value) async {
    final prefs = await _instance;
    return prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _instance;
    return prefs.getInt(key);
  }

  Future<bool> setDouble(String key, double value) async {
    final prefs = await _instance;
    return prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await _instance;
    return prefs.getDouble(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await _instance;
    return prefs.setStringList(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    final prefs = await _instance;
    return prefs.getStringList(key);
  }

  Future<bool> setJsonMap(String key, Map<String, dynamic> map) async {
    final encoded = jsonEncode(map);
    return setString(key, encoded);
  }

  Future<Map<String, dynamic>?> getJsonMap(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> remove(String key) async {
    final prefs = await _instance;
    return prefs.remove(key);
  }

  Future<bool> clearAll() async {
    final prefs = await _instance;
    return prefs.clear();
  }

  Future<bool> containsKey(String key) async {
    final prefs = await _instance;
    return prefs.containsKey(key);
  }
}
