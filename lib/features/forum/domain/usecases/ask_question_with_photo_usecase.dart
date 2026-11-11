import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/forum_question_entity.dart';
import '../repositories/forum_repository.dart';

/// Ders etiketiyle, isteğe bağlı fotoğraf ekli soru sorma.
class AskQuestionWithPhotoUseCase {
  const AskQuestionWithPhotoUseCase(this._repository);

  final ForumRepository _repository;

  static const int minLength = 10;

  Future<ForumQuestionEntity> call({
    required UserEntity actor,
    required String courseTag,
    required String topicTag,
    required String questionText,
    String? photoPath,
  }) {
    final text = questionText.trim();
    if (text.length < minLength) {
      throw const ValidationFailure('Soru en az $minLength karakter olmalıdır.');
    }
    final photoName = photoPath?.split(RegExp(r'[\\/]')).last;
    return _repository.askQuestion(
      author: actor,
      courseTag: courseTag,
      topicTag: topicTag.trim().isEmpty ? 'Genel' : topicTag.trim(),
      questionText: text,
      photoName: photoName,
    );
  }
}
