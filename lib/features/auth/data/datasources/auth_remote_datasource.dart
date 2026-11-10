import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/user_role.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> loginWithStudentNoOrEmail({
    required String identifier,
    required String password,
    String? fcmToken,
  });

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? studentNo,
    String? department,
    String? fcmToken,
  });

  Future<void> sendPasswordResetEmail({required String identifier});

  Future<Map<String, dynamic>?> getCurrentUser();

  Stream<Map<String, dynamic>?> watchAuthStateChanges();

  Future<void> updateFcmToken(String userId, String fcmToken);

  Future<void> logout();
}

/// Firebase Auth ve Firestore `users` koleksiyonu ile konuşur.
/// Öğrenci numarası ile giriş yapıldığında Firestore'dan o numaraya ait e-postayı bulup
/// (veya kurumsal uzantıya çevirip) Firebase Auth girişi yapar; kayıt aşamasında
/// seçilen rolü (`student` / `instructor`) ve FCM token'ı Firestore'a yazar.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  static const String institutionalStudentDomain = 'ogrenci.edupulse.edu.tr';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestorePaths.users);

  /// Öğrenci numarası girildiyse Firestore'dan ilgili kullanıcının e-postasını bulur,
  /// kayıt yoksa kurumsal uzantıya (`@ogrenci.edupulse.edu.tr`) çevirir.
  Future<String> _resolveEmail(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) {
      return trimmed;
    }

    try {
      final querySnapshot = await _usersCollection
          .where('studentNo', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final email = querySnapshot.docs.first.data()['email'] as String?;
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    } catch (_) {
      // Firestore sorgusu başarısız olursa kurumsal e-posta uzantısına düşer
    }

    return '$trimmed@$institutionalStudentDomain';
  }

  @override
  Future<Map<String, dynamic>> loginWithStudentNoOrEmail({
    required String identifier,
    required String password,
    String? fcmToken,
  }) async {
    final email = await _resolveEmail(identifier);

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Oturum açılamadı.',
      );
    }

    if (fcmToken != null && fcmToken.isNotEmpty) {
      await updateFcmToken(user.uid, fcmToken);
    }

    final userDoc = await _usersCollection.doc(user.uid).get();
    if (!userDoc.exists || userDoc.data() == null) {
      final fallbackData = <String, dynamic>{
        'id': user.uid,
        'uid': user.uid,
        'email': user.email ?? email,
        'fullName': user.displayName ?? '',
        'role': UserRole.student.name,
        'studentNo': identifier.contains('@') ? null : identifier.trim(),
        'fcmToken': fcmToken,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _usersCollection.doc(user.uid).set(fallbackData);
      return fallbackData;
    }

    final data = Map<String, dynamic>.from(userDoc.data()!);
    data['id'] = userDoc.id;
    return _normalizeTimestamps(data);
  }

  @override
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? studentNo,
    String? department,
    String? fcmToken,
  }) async {
    final resolvedEmail = email.trim().contains('@')
        ? email.trim()
        : '${email.trim()}@$institutionalStudentDomain';

    if (studentNo != null && studentNo.trim().isNotEmpty) {
      final existingStudent = await _usersCollection
          .where('studentNo', isEqualTo: studentNo.trim())
          .limit(1)
          .get();

      if (existingStudent.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'student-no-already-in-use',
          message: 'Bu öğrenci numarası zaten kayıtlı.',
        );
      }
    }

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: resolvedEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Kullanıcı kaydı oluşturulamadı.',
      );
    }

    await user.updateDisplayName(fullName.trim());

    final nowIso = DateTime.now().toIso8601String();
    final userData = <String, dynamic>{
      'id': user.uid,
      'uid': user.uid,
      'email': resolvedEmail,
      'fullName': fullName.trim(),
      'role': role.name,
      'studentNo': studentNo?.trim(),
      'department': department?.trim(),
      'fcmToken': fcmToken,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    };

    await _usersCollection.doc(user.uid).set(userData);
    return userData;
  }

  @override
  Future<void> sendPasswordResetEmail({required String identifier}) async {
    final email = await _resolveEmail(identifier);
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;

    final doc = await _usersCollection.doc(currentUser.uid).get();
    if (!doc.exists || doc.data() == null) {
      return {
        'id': currentUser.uid,
        'uid': currentUser.uid,
        'email': currentUser.email ?? '',
        'fullName': currentUser.displayName ?? '',
        'role': UserRole.student.name,
      };
    }

    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return _normalizeTimestamps(data);
  }

  @override
  Stream<Map<String, dynamic>?> watchAuthStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return getCurrentUser();
    });
  }

  @override
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    await _usersCollection.doc(userId).set(
      {
        'fcmToken': fcmToken,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Map<String, dynamic> _normalizeTimestamps(Map<String, dynamic> raw) {
    final normalized = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value is Timestamp) {
        normalized[key] = value.toDate().toIso8601String();
      } else {
        normalized[key] = value;
      }
    });
    return normalized;
  }
}
