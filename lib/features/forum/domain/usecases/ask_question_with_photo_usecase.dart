import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/forum_question_entity.dart';
import '../repositories/forum_repository.dart';

/// Fotoğraflı (opsiyonel) ve ders/konu etiketli yeni soru açar.
/// Yerel fotoğraf yolu verilirse datasource önce Storage'a yükler.
class AskQuestionWithPhotoUseCase {
  const AskQuestionWithPhotoUseCase(this._repository);

  final ForumRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String authorUid,
    required String authorName,
    required String courseTag,
    required String topicTag,
    required String questionText,
    String? localPhotoPath,
  }) async {
    if (questionText.trim().isEmpty || courseTag.trim().isEmpty) {
      return const Left(ServerFailure('Soru metni ve ders etiketi zorunludur.'));
    }
    return guardFailure(() async {
      await _repository.askQuestionWithPhoto(ForumQuestionEntity(
        questionId: '',
        authorUid: authorUid,
        authorName: authorName,
        courseTag: courseTag.trim(),
        topicTag: topicTag.trim(),
        questionText: questionText.trim(),
        imageUrl: localPhotoPath,
        isResolved: false,
      ));
      return unit;
    });
  }
}
