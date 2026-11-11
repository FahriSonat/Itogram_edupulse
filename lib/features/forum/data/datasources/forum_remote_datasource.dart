import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/user_role.dart';

/// Öğrencinin çektiği soru fotoğrafını Firebase Storage'a yükler, soru ve etiketleri
/// Firestore `forum_questions` koleksiyonuna yazar.
/// Eğitmen bir yanıtı "Çözüldü" olarak işaretlediğinde Atomik Batch Write ile
/// hem yanıtı `isInstructorApproved = true` hem de soruyu `isResolved = true` olarak günceller.
abstract class ForumRemoteDataSource {
  Stream<List<Map<String, dynamic>>> watchForumQuestions({
    String? courseId,
    bool? onlyResolved,
  });

  Stream<List<Map<String, dynamic>>> watchQuestionAnswers(String questionId);

  Future<String> uploadQuestionPhoto({
    required String questionId,
    required String fileName,
    File? photoFile,
    Uint8List? photoBytes,
  });

  Future<Map<String, dynamic>> askQuestionWithPhoto({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    required UserRole authorRole,
    String? courseId,
    String? courseName,
    List<String> tags = const [],
    File? photoFile,
    Uint8List? photoBytes,
    String? photoFileName,
  });

  Future<Map<String, dynamic>> postForumAnswer({
    required String questionId,
    required String content,
    required String authorId,
    required String authorName,
    required UserRole authorRole,
  });

  /// Atomik Batch Write ile hem yanıtı `isInstructorApproved = true`
  /// hem de soruyu `isResolved = true` olarak günceller.
  Future<void> markAnswerAsResolved({
    required String questionId,
    required String answerId,
    bool isResolved = true,
  });
}

class ForumRemoteDataSourceImpl implements ForumRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ForumRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _questionsRef =>
      _firestore.collection(FirestorePaths.forumQuestions);

  CollectionReference<Map<String, dynamic>> _answersRef(String questionId) =>
      _firestore.collection(FirestorePaths.forumAnswers(questionId));

  @override
  Stream<List<Map<String, dynamic>>> watchForumQuestions({
    String? courseId,
    bool? onlyResolved,
  }) {
    Query<Map<String, dynamic>> query = _questionsRef;

    if (courseId != null && courseId.isNotEmpty) {
      query = query.where('courseId', isEqualTo: courseId);
    }
    if (onlyResolved != null) {
      query = query.where('isResolved', isEqualTo: onlyResolved);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _normalizeMap(data);
      }).toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchQuestionAnswers(String questionId) {
    return _answersRef(questionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _normalizeMap(data);
      }).toList();
    });
  }

  @override
  Future<String> uploadQuestionPhoto({
    required String questionId,
    required String fileName,
    File? photoFile,
    Uint8List? photoBytes,
  }) async {
    final safeName =
        '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}';
    final ref = _storage.ref().child('forum/$questionId/$safeName');
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    UploadTask task;
    if (photoFile != null) {
      task = ref.putFile(photoFile, metadata);
    } else if (photoBytes != null) {
      task = ref.putData(photoBytes, metadata);
    } else {
      throw ArgumentError('Fotoğraf dosyası belirtilmelidir.');
    }

    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }

  @override
  Future<Map<String, dynamic>> askQuestionWithPhoto({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    required UserRole authorRole,
    String? courseId,
    String? courseName,
    List<String> tags = const [],
    File? photoFile,
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    final docRef = _questionsRef.doc();
    String? imageUrl;

    if (photoFile != null || photoBytes != null) {
      imageUrl = await uploadQuestionPhoto(
        questionId: docRef.id,
        fileName: photoFileName ?? 'question_photo.jpg',
        photoFile: photoFile,
        photoBytes: photoBytes,
      );
    }

    final now = DateTime.now();
    final payload = <String, dynamic>{
      'id': docRef.id,
      'title': title.trim(),
      'content': content.trim(),
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole.name,
      'courseId': courseId,
      'courseName': courseName,
      'tags': tags,
      'imageUrl': imageUrl,
      'answerCount': 0,
      'isResolved': false,
      'resolvedAnswerId': null,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await docRef.set(payload);
    return _normalizeMap(payload);
  }

  @override
  Future<Map<String, dynamic>> postForumAnswer({
    required String questionId,
    required String content,
    required String authorId,
    required String authorName,
    required UserRole authorRole,
  }) async {
    final questionDocRef = _questionsRef.doc(questionId);
    final answerDocRef = _answersRef(questionId).doc();
    final now = DateTime.now();

    final isInstructor =
        authorRole == UserRole.instructor || authorRole == UserRole.admin;

    final answerPayload = <String, dynamic>{
      'id': answerDocRef.id,
      'questionId': questionId,
      'content': content.trim(),
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole.name,
      'isInstructorAnswer': isInstructor,
      'isInstructorApproved': false,
      'isResolved': false,
      'createdAt': Timestamp.fromDate(now),
    };

    final batch = _firestore.batch();
    batch.set(answerDocRef, answerPayload);
    batch.update(questionDocRef, {
      'answerCount': FieldValue.increment(1),
      'updatedAt': Timestamp.fromDate(now),
    });
    await batch.commit();

    return _normalizeMap(answerPayload);
  }

  @override
  Future<void> markAnswerAsResolved({
    required String questionId,
    required String answerId,
    bool isResolved = true,
  }) async {
    final questionDocRef = _questionsRef.doc(questionId);
    final answerDocRef = _answersRef(questionId).doc(answerId);
    final now = DateTime.now();

    // Atomik Batch Write: hem yanıtı isInstructorApproved = true hem de soruyu isResolved = true yapar
    final batch = _firestore.batch();
    batch.update(answerDocRef, {
      'isInstructorApproved': isResolved,
      'isResolved': isResolved,
    });
    batch.update(questionDocRef, {
      'isResolved': isResolved,
      'resolvedAnswerId': isResolved ? answerId : null,
      'updatedAt': Timestamp.fromDate(now),
    });
    await batch.commit();
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}
