import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/user_model.dart';

/// [AuthRemoteDataSource] kimlik doğrulama backend'ini soyutlar.
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String identifier, required String password});

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String schoolNo,
    required String password,
    required UserRole role,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<UserModel?> getUser(String uid);

  Future<List<UserModel>> getUsersByRole(UserRole role);
}

/// Kullanıcıları yerel veritabanındaki `users` koleksiyonunda tutan implementasyon.
class LocalAuthRemoteDataSource implements AuthRemoteDataSource {
  LocalAuthRemoteDataSource(this._storage);

  final LocalStorageService _storage;

  List<Map<String, dynamic>> get _users => _storage.getAll(FirestorePaths.users);

  @override
  Future<UserModel> login({required String identifier, required String password}) async {
    final id = identifier.trim().toLowerCase();
    final doc = _users.where((u) {
      return (u['schoolNo'] as String? ?? '') == id || (u['email'] as String? ?? '').toLowerCase() == id;
    }).firstOrNull;

    if (doc == null) {
      throw const AuthException('Bu numara veya e-posta ile kayıtlı kullanıcı bulunamadı.');
    }
    if (doc['password'] != password) {
      throw const AuthException('Şifre hatalı. Lütfen tekrar deneyiniz.');
    }
    return UserModel.fromJson(doc);
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String schoolNo,
    required String password,
    required UserRole role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedNo = schoolNo.trim();
    for (final u in _users) {
      if ((u['email'] as String? ?? '').toLowerCase() == normalizedEmail) {
        throw const AuthException('Bu e-posta adresi zaten kayıtlı.');
      }
      if (u['schoolNo'] == normalizedNo) {
        throw const AuthException('Bu öğrenci / sicil numarası zaten kayıtlı.');
      }
    }

    final user = UserModel(
      uid: _storage.generateId(role.isStudent ? 'u' : 'i'),
      fullName: fullName.trim(),
      email: normalizedEmail,
      schoolNo: normalizedNo,
      role: role,
      department: role.isStudent ? 'SoftITO Akademi • Mobil Yazılım' : 'Eğitmen',
    );
    await _storage.upsert(FirestorePaths.users, {
      ...user.toJson(),
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final exists = _users.any((u) => (u['email'] as String? ?? '').toLowerCase() == normalized);
    if (!exists) {
      throw const NotFoundException('Bu e-posta adresiyle kayıtlı bir hesap bulunamadı.');
    }
    // Yerel backend e-posta gönderemez; gerçek backend'de burada sıfırlama
    // bağlantısı içeren e-posta tetiklenir.
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = _storage.getById(FirestorePaths.users, uid);
    return doc == null ? null : UserModel.fromJson(doc);
  }

  @override
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    final list = _users.where((u) => u['role'] == role.toJson()).map(UserModel.fromJson).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }
}
