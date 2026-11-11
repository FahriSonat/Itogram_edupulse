import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/features/forum/data/models/forum_answer_model.dart';
import 'package:itogram_edupulse/features/forum/domain/entities/forum_answer_entity.dart';

void main() {
  const ForumAnswerModel model = ForumAnswerModel(
    answerId: 'a-1',
    responderName: 'Eğitmen',
    responderRole: 'instructor',
    answerText: 'Cubit fonksiyon, Bloc event tabanlıdır.',
    isInstructorApproved: true,
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'responderName': 'Eğitmen',
    'responderRole': 'instructor',
    'answerText': 'Cubit fonksiyon, Bloc event tabanlıdır.',
    'isInstructorApproved': true,
  };

  group('ForumAnswerModel', () {
    test('ForumAnswerEntity alt sınıfıdır', () {
      expect(model, isA<ForumAnswerEntity>());
    });

    test('fromFirestore tüm alanları doğru okur', () {
      expect(ForumAnswerModel.fromFirestore(json, 'a-1'), model);
    });

    test('toJson doğru map üretir', () {
      expect(model.toJson(), json);
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(
        ForumAnswerModel.fromFirestore(model.toJson(), model.answerId),
        model,
      );
    });

    test('onay bayrağı yoksa false olur', () {
      final Map<String, dynamic> noFlag = Map<String, dynamic>.of(json)
        ..remove('isInstructorApproved');
      expect(
        ForumAnswerModel.fromFirestore(noFlag, 'a-1').isInstructorApproved,
        isFalse,
      );
    });

    test('copyWith sadece verilen alanı değiştirir', () {
      final ForumAnswerModel updated =
          model.copyWith(isInstructorApproved: false);
      expect(updated.isInstructorApproved, isFalse);
      expect(updated.answerText, model.answerText);
      expect(updated.copyWith(isInstructorApproved: true), model);
    });
  });
}
