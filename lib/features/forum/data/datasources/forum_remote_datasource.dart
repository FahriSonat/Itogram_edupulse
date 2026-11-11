import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/forum_answer_model.dart';
import '../models/forum_question_model.dart';

abstract class ForumRemoteDataSource {
  Stream<List<ForumQuestionModel>> watchQuestions();
  Stream<List<ForumAnswerModel>> watchAnswers();
  ForumQuestionModel? getQuestion(String id);
  List<ForumAnswerModel> getAnswers(String questionId);
  Future<void> saveQuestion(ForumQuestionModel question);
  Future<void> saveAnswers(List<ForumAnswerModel> answers);
  String newId(String prefix);
}

class LocalForumRemoteDataSource implements ForumRemoteDataSource {
  LocalForumRemoteDataSource(this._storage);

  final LocalStorageService _storage;

  @override
  Stream<List<ForumQuestionModel>> watchQuestions() => _storage.watch(FirestorePaths.forumQuestions).map((docs) {
    final list = docs.map(ForumQuestionModel.fromJson).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });

  @override
  Stream<List<ForumAnswerModel>> watchAnswers() => _storage.watch(FirestorePaths.forumAnswers).map((docs) {
    final list = docs.map(ForumAnswerModel.fromJson).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  });

  @override
  ForumQuestionModel? getQuestion(String id) {
    final doc = _storage.getById(FirestorePaths.forumQuestions, id);
    return doc == null ? null : ForumQuestionModel.fromJson(doc);
  }

  @override
  List<ForumAnswerModel> getAnswers(String questionId) => _storage
      .getAll(FirestorePaths.forumAnswers)
      .where((d) => d['questionId'] == questionId)
      .map(ForumAnswerModel.fromJson)
      .toList();

  @override
  Future<void> saveQuestion(ForumQuestionModel question) =>
      _storage.upsert(FirestorePaths.forumQuestions, question.toJson());

  @override
  Future<void> saveAnswers(List<ForumAnswerModel> answers) =>
      _storage.upsertAll(FirestorePaths.forumAnswers, answers.map((a) => a.toJson()).toList());

  @override
  String newId(String prefix) => _storage.generateId(prefix);
}
