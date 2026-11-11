import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../models/forum_answer_model.dart';
import '../models/forum_question_model.dart';

/// Öğrencinin çektiği soru fotoğrafını Firebase Storage'a yükler, soru ve etiketleri
/// Firestore `forum_questions` koleksiyonuna yazar.
/// Eğitmen bir yanıtı "Çözüldü" olarak işaretlediğinde Atomik Batch Write ile
/// hem yanıtı `isInstructorApproved = true` hem de soruyu `isResolved = true` olarak günceller.
abstract class ForumRemoteDataSource {
  Stream<List<ForumQuestionModel>> watchForumQuestions({
    String? courseTag,
    String? topicTag,
  });

  Future<void> askQuestionWithPhoto(ForumQuestionModel question);

  Future<String> uploadQuestionPhoto({
    required String questionId,
    required String fileName,
    File? photoFile,
    Uint8List? photoBytes,
  });

  Stream<List<ForumAnswerModel>> watchForumAnswers(String questionId);

  Future<void> postForumAnswer(String questionId, ForumAnswerModel answer);

  Future<void> markAnswerAsResolved(String questionId, String answerId);
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
  Stream<List<ForumQuestionModel>> watchForumQuestions({
    String? courseTag,
    String? topicTag,
  }) {
    Query<Map<String, dynamic>> query = _questionsRef;

    if (courseTag != null && courseTag.isNotEmpty) {
      query = query.where('courseTag', isEqualTo: courseTag);
    }
    if (topicTag != null && topicTag.isNotEmpty) {
      query = query.where('topicTag', isEqualTo: topicTag);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ForumQuestionModel.fromFirestore(doc.data(), doc.id))
          .toList();
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
  Future<void> askQuestionWithPhoto(ForumQuestionModel question) async {
    final docRef = question.questionId.isNotEmpty
        ? _questionsRef.doc(question.questionId)
        : _questionsRef.doc();

    String? resolvedImageUrl = question.imageUrl;

    // Eğer imageUrl yerel bir dosya yoluysa önce Firebase Storage'a yükle
    if (resolvedImageUrl != null &&
        resolvedImageUrl.isNotEmpty &&
        !resolvedImageUrl.startsWith('http://') &&
        !resolvedImageUrl.startsWith('https://')) {
      final localPhoto = File(resolvedImageUrl);
      if (await localPhoto.exists()) {
        resolvedImageUrl = await uploadQuestionPhoto(
          questionId: docRef.id,
          fileName: localPhoto.uri.pathSegments.last,
          photoFile: localPhoto,
        );
      }
    }

    final modelToSave = question.copyWith(
      questionId: docRef.id,
      imageUrl: resolvedImageUrl,
    );

    await docRef.set(modelToSave.toJson());
  }

  @override
  Stream<List<ForumAnswerModel>> watchForumAnswers(String questionId) {
    return _answersRef(questionId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ForumAnswerModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> postForumAnswer(
    String questionId,
    ForumAnswerModel answer,
  ) async {
    final docRef = answer.answerId.isNotEmpty
        ? _answersRef(questionId).doc(answer.answerId)
        : _answersRef(questionId).doc();

    await docRef.set(answer.toJson());
  }

  @override
  Future<void> markAnswerAsResolved(
    String questionId,
    String answerId,
  ) async {
    final questionDocRef = _questionsRef.doc(questionId);
    final answerDocRef = _answersRef(questionId).doc(answerId);

    // Atomik Batch Write: hem yanıtı isInstructorApproved = true hem de soruyu isResolved = true yapar
    final batch = _firestore.batch();
    batch.update(answerDocRef, {
      'isInstructorApproved': true,
    });
    batch.update(questionDocRef, {
      'isResolved': true,
    });
    await batch.commit();
  }
}
