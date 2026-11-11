// Geliştirici 5 & 6 — 2.6 Forum: soru sor, yanıtla, "Çözüldü" (yalnızca eğitmen — Kural 5).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/core/enums/view_status.dart';
import 'package:itogram_edupulse/features/forum/domain/entities/forum_answer_entity.dart';
import 'package:itogram_edupulse/features/forum/domain/entities/forum_question_entity.dart';
import 'package:itogram_edupulse/features/forum/presentation/cubit/forum_cubit.dart';
import 'package:itogram_edupulse/features/forum/presentation/pages/forum_page.dart';
import 'package:itogram_edupulse/features/forum/presentation/pages/forum_question_detail_page.dart';
import 'package:itogram_edupulse/features/forum/presentation/widgets/instructor_resolved_answer_card.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/page_harness.dart';

const ForumQuestionEntity _q = ForumQuestionEntity(
  questionId: 'q-1',
  authorUid: 'uid-student',
  authorName: 'Merve',
  courseTag: 'MOB101',
  topicTag: 'Cubit',
  questionText: 'BlocProvider ile BlocProvider.value farkı nedir?',
  isResolved: false,
);

void seedAnswer(FakeForumRepository repo) {
  repo.answers['q-1'] = LiveList<ForumAnswerEntity>([
    const ForumAnswerEntity(
      answerId: 'a-1',
      responderName: 'Fahri Hoca',
      responderRole: 'instructor',
      answerText: 'value mevcut bir cubit örneğini paylaşır.',
      isInstructorApproved: false,
    ),
  ]);
}

void main() {
  group('ForumCubit', () {
    late TestBackend backend;
    late ForumCubit cubit;
    setUp(() async {
      backend = TestBackend();
      await backend.register();
      backend.forum.questions.items.addAll([
        _q,
        const ForumQuestionEntity(
          questionId: 'q-2',
          authorUid: 'u2',
          authorName: 'Ayberk',
          courseTag: 'ALG201',
          topicTag: 'Graf',
          questionText: 'Dijkstra negatif kenarda çalışır mı?',
          isResolved: true,
        ),
      ]);
      cubit = GetIt.instance<ForumCubit>();
    });
    tearDown(() => cubit.close());

    Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 10));

    test('sorular canlı izlenir ve ders etiketine göre filtrelenir', () async {
      cubit.start();
      await flush();
      expect(cubit.state.status, ViewStatus.loaded);
      expect(cubit.state.questions.length, 2);

      cubit.filterByCourse('ALG201');
      await flush();
      expect(cubit.state.questions.single.questionId, 'q-2');

      cubit.filterByCourse(null);
      await flush();
      expect(cubit.state.questions.length, 2);
    });

    test('fotoğraflı soru sorulur; metinsiz soru reddedilir', () async {
      cubit.start();
      await flush();
      expect(
        await cubit.askQuestion(
          authorUid: 'uid-student',
          authorName: 'Merve',
          courseTag: 'MOB101',
          topicTag: 'GoRouter',
          questionText: 'ShellRoute nasıl çalışır?',
          localPhotoPath: '/tmp/soru.jpg',
        ),
        isTrue,
      );
      await flush();
      expect(backend.forum.questions.items.last.imageUrl, '/tmp/soru.jpg');
      expect(cubit.state.questions.length, 3);

      expect(
        await cubit.askQuestion(authorUid: 'u', authorName: 'n', courseTag: 'MOB101', topicTag: '', questionText: '  '),
        isFalse,
      );
    });

    test('yanıt gönderilir ve canlı listeye düşer', () async {
      cubit
        ..start()
        ..openQuestion('q-1');
      await flush();
      await cubit.postAnswer(
        questionId: 'q-1',
        responderName: 'Ayberk',
        responderRole: UserRole.student,
        answerText: 'Bence value yeni örnek oluşturmaz.',
      );
      await flush();
      expect(cubit.state.answers.single.responderRole, 'student');
    });

    test('Kural 5: öğrenci yanıtı "Çözüldü" yapamaz, eğitmen yapabilir', () async {
      await cubit.markResolved(questionId: 'q-1', answerId: 'a-1', role: UserRole.student);
      expect(backend.forum.resolved, isEmpty);
      expect(cubit.state.actionMessage, contains('Yalnızca eğitmen'));

      await cubit.markResolved(questionId: 'q-1', answerId: 'a-1', role: UserRole.instructor);
      expect(backend.forum.resolved.single, ('q-1', 'a-1'));
    });
  });

  group('ForumPage / ForumQuestionDetailPage', () {
    late TestBackend backend;
    setUp(() async {
      backend = TestBackend();
      await backend.register();
      backend.forum.questions.items.add(_q);
      seedAnswer(backend.forum);
    });

    testWidgets('öğrenci soru akışını ve "Soru Sor" butonunu görür, kriz yayını butonunu görmez', (tester) async {
      await pumpPage(tester, const ForumPage(), backend: backend);
      expect(find.text(_q.questionText), findsOneWidget);
      expect(find.byKey(const Key('forum_ask')), findsOneWidget);
      expect(find.byKey(const Key('forum_crisis')), findsNothing);
    });

    testWidgets('eğitmen "Anlık Kriz Yayını" butonunu görür', (tester) async {
      await pumpPage(tester, const ForumPage(), backend: backend, role: UserRole.instructor);
      expect(find.byKey(const Key('forum_crisis')), findsOneWidget);
    });

    testWidgets('detayda öğrenci "Çözüldü Olarak İşaretle" yetkisine sahip değildir', (tester) async {
      await pumpPage(tester, const ForumQuestionDetailPage(questionId: 'q-1'), backend: backend);
      final card = tester.widget<InstructorResolvedAnswerCard>(find.byType(InstructorResolvedAnswerCard));
      expect(card.canMarkAsResolved, isFalse);
    });

    testWidgets('eğitmen detayda cevabı onaylayabilir', (tester) async {
      await pumpPage(tester, const ForumQuestionDetailPage(questionId: 'q-1'), backend: backend, role: UserRole.instructor);
      final card = tester.widget<InstructorResolvedAnswerCard>(find.byType(InstructorResolvedAnswerCard));
      expect(card.canMarkAsResolved, isTrue);
      card.onMarkAsResolved!();
      await settle(tester);
      expect(backend.forum.resolved.single, ('q-1', 'a-1'));
    });

    testWidgets('detayda yanıt yazılıp gönderilir, alan temizlenir', (tester) async {
      await pumpPage(tester, const ForumQuestionDetailPage(questionId: 'q-1'), backend: backend);
      await tester.enterText(find.byKey(const Key('forum_answer_field')), 'Teşekkürler hocam!');
      await tester.tap(find.byKey(const Key('forum_answer_send')));
      await settle(tester);

      expect(backend.forum.answers['q-1']!.items.last.answerText, 'Teşekkürler hocam!');
      expect(find.text('Teşekkürler hocam!'), findsOneWidget, reason: 'yanıt listede görünür');
    });
  });
}
