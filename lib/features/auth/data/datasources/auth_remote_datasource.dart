import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/user_role.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithStudentNo(
    String studentNo,
    String password, {
    String? fcmToken,
  });

  Future<UserModel> registerUser({
    required String studentNo,
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? fcmToken,
  });

  Future<void> sendPasswordResetEmail(String identifier);

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> watchAuthStateChanges();

  Future<void> updateFcmToken(String userId, String fcmToken);

  Future<void> logout();
}

/// Firebase Auth ve Firestore `users` koleksiyonu ile konuşur.
/// Öğrenci numarası ile giriş yapıldığında Firestore'dan o numaraya ait e-postayı bulup
/// (veya kurumsal uzantıya çevirip) Firebase Auth girişi yapar; kayıt aşamasında
/// seçilen rolü (`student` / `instructor`), `studentOrStaffNo` bilgisini ve FCM token'ı Firestore'a yazar.
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

  /// Öğrenci numarası girildiyse Firestore `users` koleksiyonundan `studentOrStaffNo`
  /// (veya `studentNo`) alanını sorgulayarak e-postasını bulur; bulunamazsa kurumsal uzantıya çevirir.
  Future<String> _resolveEmail(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) {
      return trimmed;
    }

    try {
      final byStudentOrStaffNo = await _usersCollection
          .where('studentOrStaffNo', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (byStudentOrStaffNo.docs.isNotEmpty) {
        final email = byStudentOrStaffNo.docs.first.data()['email'] as String?;
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }

      final byStudentNo = await _usersCollection
          .where('studentNo', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (byStudentNo.docs.isNotEmpty) {
        final email = byStudentNo.docs.first.data()['email'] as String?;
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
  Future<UserModel> loginWithStudentNo(
    String studentNo,
    String password, {
    String? fcmToken,
  }) async {
    final trimmedIdentifier = studentNo.trim();
    final email = await _resolveEmail(trimmedIdentifier);

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
    final inferredNo = !trimmedIdentifier.contains('@')
        ? trimmedIdentifier
        : email.split('@').first;

    if (!userDoc.exists || userDoc.data() == null) {
      final fallbackModel = UserModel(
        uid: user.uid,
        studentOrStaffNo: inferredNo,
        fullName: user.displayName ?? '',
        email: user.email ?? email,
        role: UserRole.student,
        fcmToken: fcmToken,
      );
      await _usersCollection.doc(user.uid).set({
        ...fallbackModel.toJson(),
        'studentNo': inferredNo,
      });
      return fallbackModel;
    }

    final data = Map<String, dynamic>.from(userDoc.data()!);
    final existingNo =
        (data['studentOrStaffNo'] ?? data['studentNo'] ?? '').toString().trim();
    if (existingNo.isEmpty) {
      data['studentOrStaffNo'] = inferredNo;
      data['studentNo'] = inferredNo;
      await _usersCollection.doc(user.uid).set(
        {
          'studentOrStaffNo': inferredNo,
          'studentNo': inferredNo,
        },
        SetOptions(merge: true),
      );
    } else if (data['studentOrStaffNo'] == null) {
      data['studentOrStaffNo'] = existingNo;
    }

    return UserModel.fromFirestore(data, userDoc.id);
  }

  @override
  Future<UserModel> registerUser({
    required String studentNo,
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? fcmToken,
  }) async {
    final trimmedEmail = email.trim();
    final resolvedEmail = trimmedEmail.contains('@')
        ? trimmedEmail
        : '$trimmedEmail@$institutionalStudentDomain';

    final effectiveNo = studentNo.trim().isNotEmpty
        ? studentNo.trim()
        : resolvedEmail.split('@').first;

    if (effectiveNo.isNotEmpty) {
      final existingUser = await _usersCollection
          .where('studentOrStaffNo', isEqualTo: effectiveNo)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'student-no-already-in-use',
          message: 'Bu öğrenci/personel numarası zaten kayıtlı.',
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

    final userModel = UserModel(
      uid: user.uid,
      studentOrStaffNo: effectiveNo,
      fullName: fullName.trim(),
      email: resolvedEmail,
      role: role,
      fcmToken: fcmToken,
    );

    await _usersCollection.doc(user.uid).set({
      ...userModel.toJson(),
      'studentNo': effectiveNo,
    });

    return userModel;
  }

  @override
  Future<void> sendPasswordResetEmail(String identifier) async {
    final email = await _resolveEmail(identifier);
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;

    final doc = await _usersCollection.doc(currentUser.uid).get();
    if (!doc.exists || doc.data() == null) {
      return UserModel(
        uid: currentUser.uid,
        studentOrStaffNo: (currentUser.email ?? '').split('@').first,
        fullName: currentUser.displayName ?? '',
        email: currentUser.email ?? '',
        role: UserRole.student,
      );
    }

    final data = Map<String, dynamic>.from(doc.data()!);
    data['studentOrStaffNo'] ??=
        (data['studentNo'] ?? (currentUser.email ?? '').split('@').first)
            .toString();
    return UserModel.fromFirestore(data, doc.id);
  }

  @override
  Stream<UserModel?> watchAuthStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return getCurrentUser();
    });
  }

  @override
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    await _usersCollection.doc(userId).set(
      {'fcmToken': fcmToken},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
