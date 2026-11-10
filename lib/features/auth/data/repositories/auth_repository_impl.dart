import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Firebase kimlik doğrulama hatalarını Türkçe ve anlaşılır hata nesnelerine dönüştürür.
class AuthFailure extends Equatable implements Exception {
  final String message;
  final String? code;

  const AuthFailure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => message;
}

/// AuthRemoteDataSource ve AuthLocalDataSource'u birleştirir;
/// Firebase hatalarını Türkçe ve anlaşılır AuthFailure nesnelerine dönüştürür.
class AuthRepositoryImpl {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final FcmNotificationService? fcmService;
  final AnalyticsService? analyticsService;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
    NetworkInfo? networkInfo,
    this.fcmService,
    this.analyticsService,
  })  : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl(),
        _localDataSource = localDataSource ?? AuthLocalDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  Future<Map<String, dynamic>> loginWithStudentNo({
    required String identifier,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const AuthFailure(
        'İnternet bağlantısı bulunamadı. Lütfen bağlantınızı kontrol edin.',
        code: 'network-request-failed',
      );
    }

    try {
      final token = await fcmService?.getFcmToken();
      final userMap = await _remoteDataSource.loginWithStudentNoOrEmail(
        identifier: identifier,
        password: password,
        fcmToken: token,
      );

      await _localDataSource.cacheUser(userMap);
      await _syncAnalytics(userMap);

      return userMap;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Giriş yapılırken beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? studentNo,
    String? department,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const AuthFailure(
        'İnternet bağlantısı bulunamadı. Lütfen bağlantınızı kontrol edin.',
        code: 'network-request-failed',
      );
    }

    try {
      final token = await fcmService?.getFcmToken();
      final userMap = await _remoteDataSource.registerUser(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        studentNo: studentNo,
        department: department,
        fcmToken: token,
      );

      await _localDataSource.cacheUser(userMap);
      await _syncAnalytics(userMap);

      return userMap;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Kayıt oluşturulurken beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<void> sendPasswordResetMail({required String identifier}) async {
    if (!await _networkInfo.isConnected) {
      throw const AuthFailure(
        'İnternet bağlantısı bulunamadı. Lütfen bağlantınızı kontrol edin.',
        code: 'network-request-failed',
      );
    }

    try {
      await _remoteDataSource.sendPasswordResetEmail(identifier: identifier);
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Şifre sıfırlama e-postası gönderilemedi: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    return _networkInfo.executeWithOfflineFallback<Map<String, dynamic>?>(
      onOnline: () async {
        final remoteUser = await _remoteDataSource.getCurrentUser();
        if (remoteUser != null) {
          await _localDataSource.cacheUser(remoteUser);
          return remoteUser;
        }
        return _localDataSource.getLastCachedUser();
      },
      onOffline: (_) => _localDataSource.getLastCachedUser(),
    );
  }

  Stream<Map<String, dynamic>?> watchAuthStateChanges() {
    return _remoteDataSource.watchAuthStateChanges();
  }

  Future<void> logout() async {
    await _remoteDataSource.logout();
    await _localDataSource.clearAuthCache();
    await analyticsService?.clearUserIdentity();
  }

  Future<void> _syncAnalytics(Map<String, dynamic> userMap) async {
    final userId = (userMap['id'] ?? userMap['uid'])?.toString();
    if (userId == null) return;

    await analyticsService?.setUserIdentity(
      userId: userId,
      role: userMap['role']?.toString(),
      department: userMap['department']?.toString(),
    );
    await analyticsService?.logLogin();
  }

  AuthFailure mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure(
          e.message ?? 'Bu bilgilere ait kayıtlı kullanıcı bulunamadı.',
          code: e.code,
        );
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure(
          'Öğrenci numarası/e-posta veya şifre hatalı.',
          code: e.code,
        );
      case 'email-already-in-use':
        return AuthFailure(
          'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.',
          code: e.code,
        );
      case 'student-no-already-in-use':
        return AuthFailure(
          'Bu öğrenci numarası sistemde zaten kayıtlı.',
          code: e.code,
        );
      case 'weak-password':
        return AuthFailure(
          'Şifreniz çok zayıf. Lütfen en az 6 karakterli güçlü bir şifre seçin.',
          code: e.code,
        );
      case 'invalid-email':
        return AuthFailure(
          'Lütfen geçerli bir kurumsal e-posta veya öğrenci numarası girin.',
          code: e.code,
        );
      case 'user-disabled':
        return AuthFailure(
          'Bu kullanıcı hesabı yönetici tarafından askıya alınmış.',
          code: e.code,
        );
      case 'too-many-requests':
        return AuthFailure(
          'Çok fazla başarısız giriş denemesi yaptınız. Lütfen biraz bekleyip tekrar deneyin.',
          code: e.code,
        );
      case 'network-request-failed':
        return AuthFailure(
          'Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin.',
          code: e.code,
        );
      default:
        return AuthFailure(
          e.message ?? 'Kimlik doğrulama işlemi sırasında bir hata oluştu (${e.code}).',
          code: e.code,
        );
    }
  }
}
