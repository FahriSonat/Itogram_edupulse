import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/features/forum/data/models/forum_question_model.dart';
import 'package:itogram_edupulse/features/forum/domain/entities/forum_question_entity.dart';

void main() {
  const ForumQuestionModel model = ForumQuestionModel(
    questionId: 'q-1',
    authorUid: 'uid-1',
    authorName: 'Merve Kedersiz',
    courseTag: 'Mobil Programlama',
    topicTag: 'BLoC',
    questionText: 'Cubit ile Bloc farkı nedir?',
    imageUrl: 'https://storage.example.com/soru.jpg',
    isResolved: false,
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'authorUid': 'uid-1',
    'authorName': 'Merve Kedersiz',
    'courseTag': 'Mobil Programlama',
    'topicTag': 'BLoC',
    'questionText': 'Cubit ile Bloc farkı nedir?',
    'imageUrl': 'https://storage.example.com/soru.jpg',
    'isResolved': false,
  };

  group('ForumQuestionModel', () {
    test('ForumQuestionEntity alt sınıfıdır', () {
      expect(model, isA<ForumQuestionEntity>());
    });

    test('fromFirestore tüm alanları doğru okur', () {
      expect(ForumQuestionModel.fromFirestore(json, 'q-1'), model);
    });

    test('toJson doğru map üretir', () {
      expect(model.toJson(), json);
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(
        ForumQuestionModel.fromFirestore(model.toJson(), model.questionId),
        model,
      );
    });

    test('fotoğrafsız soruda imageUrl null olur', () {
      final Map<String, dynamic> noImage = Map<String, dynamic>.of(json)
        ..remove('imageUrl');
      expect(ForumQuestionModel.fromFirestore(noImage, 'q-1').imageUrl, isNull);
    });

    test('isResolved yoksa false olur', () {
      final Map<String, dynamic> noFlag = Map<String, dynamic>.of(json)
        ..remove('isResolved');
      expect(ForumQuestionModel.fromFirestore(noFlag, 'q-1').isResolved, isFalse);
    });

    test('copyWith ile soru çözüldü olarak işaretlenebilir', () {
      final ForumQuestionModel resolved = model.copyWith(isResolved: true);
      expect(resolved.isResolved, isTrue);
      expect(resolved.questionText, model.questionText);
      expect(resolved.copyWith(isResolved: false), model);
    });
  });
}
