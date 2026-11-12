import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/forum/presentation/widgets/ask_question_modal.dart';
import 'package:itogram_edupulse/features/forum/presentation/widgets/forum_question_card.dart';
import 'package:itogram_edupulse/features/forum/presentation/widgets/instructor_resolved_answer_card.dart';

import '../../helpers/design_test_harness.dart';

void main() {
  group('AskQuestionModal', () {
    testWidgets('Kamera / Galeri seçimi sunar ve seçilen fotoğrafla soruyu gönderir', (tester) async {
      Map<String, Object?>? asked;
      var cameraUsed = false;
      await pumpDesign(
        tester,
        AskQuestionModal(
          courseTags: const ['Flutter', 'Firebase'],
          onPickFromCamera: () async {
            cameraUsed = true;
            return '/tmp/kamera.jpg';
          },
          onPickFromGallery: () async => '/tmp/galeri.png',
          onAskQuestion: ({required courseTag, required topicTag, required questionText, localPhotoPath}) async {
            asked = {'course': courseTag, 'topic': topicTag, 'text': questionText, 'photo': localPhotoPath};
          },
        ),
        scrollable: false,
      );

      await tester.enterText(find.byKey(const ValueKey('topic_field')), 'Bloc Pattern');
      await tester.enterText(find.byKey(const ValueKey('question_field')), 'Cubit ne zaman tercih edilir?');
      await tester.tap(find.text('Fotoğraf Ekle (Kamera / Galeri)'));
      await tester.pumpAndSettle();
      expect(find.text('Kamera ile Çek'), findsOneWidget);
      expect(find.text('Galeriden Seç'), findsOneWidget);

      await tester.tap(find.text('Kamera ile Çek'));
      await tester.pumpAndSettle();
      expect(cameraUsed, isTrue);
      expect(find.text('kamera.jpg'), findsOneWidget);

      await tester.ensureVisible(find.text('Soruyu Kampüs Forumuna Gönder'));
      await tester.tap(find.text('Soruyu Kampüs Forumuna Gönder'));
      await tester.pump();
      expect(asked, {
        'course': 'Flutter',
        'topic': 'Bloc Pattern',
        'text': 'Cubit ne zaman tercih edilir?',
        'photo': '/tmp/kamera.jpg',
      });
    });

    testWidgets('tek kaynak verilirse doğrudan onu kullanır; konu boşsa göndermez', (tester) async {
      var called = false;
      await pumpDesign(
        tester,
        AskQuestionModal(
          courseTags: const ['Flutter'],
          onPickFromGallery: () async => 'C:\\foto\\ekran.png',
          onAskQuestion: ({required courseTag, required topicTag, required questionText, localPhotoPath}) async {
            called = true;
          },
        ),
        scrollable: false,
      );
      await tester.tap(find.text('Fotoğraf Ekle (Kamera / Galeri)'));
      await tester.pumpAndSettle();
      expect(find.text('Kamera ile Çek'), findsNothing);
      expect(find.text('ekran.png'), findsOneWidget);

      await tester.ensureVisible(find.text('Soruyu Kampüs Forumuna Gönder'));
      await tester.tap(find.text('Soruyu Kampüs Forumuna Gönder'));
      await tester.pump();
      expect(called, isFalse);
      expect(find.text('Konu etiketi gerekli'), findsOneWidget);
    });
  });

  group('Forum kartları', () {
    testWidgets('ForumQuestionCard etiketleri ve Çözüldü rozetini gösterir', (tester) async {
      await pumpDesign(
        tester,
        ForumQuestionCard(
          authorName: 'Ayşe',
          courseTag: 'Flutter',
          topicTag: 'State',
          questionText: 'setState neden yasak?',
          createdAt: DateTime(2026, 11, 9),
          isResolved: true,
          answerCount: 3,
        ),
      );
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('#State'), findsOneWidget);
      expect(find.text('Çözüldü'), findsOneWidget);
      expect(find.text('09.11.2026'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('onaylı cevap "Çözüldü / Eğitmen Onaylı Cevap" vurgusuyla çizilir', (tester) async {
      await pumpDesign(
        tester,
        InstructorResolvedAnswerCard(
          responderName: 'Mustafa Hoca',
          responderRole: UserRole.instructor,
          answerText: 'BLoC kullanın.',
          answeredAt: DateTime(2026, 11, 10, 14, 5),
          isInstructorApproved: true,
          canMarkAsResolved: true,
          onMarkAsResolved: () {},
        ),
      );
      expect(find.text(InstructorResolvedAnswerCard.approvedLabel), findsOneWidget);
      expect(find.text('Eğitmen'), findsOneWidget);
      expect(find.text('Çözüldü Olarak İşaretle'), findsNothing, reason: 'Zaten onaylı');
    });

    testWidgets('eğitmen onaylanmamış cevabı Çözüldü olarak işaretleyebilir', (tester) async {
      var marked = false;
      await pumpDesign(
        tester,
        InstructorResolvedAnswerCard(
          responderName: 'Ali',
          responderRole: UserRole.student,
          answerText: 'Provider da olur.',
          answeredAt: DateTime(2026, 11, 10),
          canMarkAsResolved: true,
          onMarkAsResolved: () => marked = true,
        ),
      );
      expect(find.text('Öğrenci'), findsOneWidget);
      await tester.tap(find.text('Çözüldü Olarak İşaretle'));
      expect(marked, isTrue);
    });
  });

  testWidgets('forum bileşenleri hiçbir ekran koşulunda taşmaz', (tester) async {
    await expectNoLayoutErrors(
      tester,
      () => ForumQuestionCard(
        authorName: 'Çok Uzun İsimli Bir Öğrenci Adı Soyadı',
        courseTag: 'İleri Seviye Mobil Uygulama Geliştirme',
        topicTag: 'Durum yönetimi ve reaktif akışlar',
        questionText: 'Soru metni ' * 20,
        createdAt: DateTime(2026, 11, 9),
        isResolved: true,
        hasImage: true,
        answerCount: 12,
      ),
    );
    await expectNoLayoutErrors(
      tester,
      () => InstructorResolvedAnswerCard(
        responderName: 'Prof. Dr. Çok Uzun İsimli Eğitmen Adı',
        responderRole: UserRole.instructor,
        answerText: 'Cevap ' * 30,
        answeredAt: DateTime(2026, 11, 10),
        isInstructorApproved: true,
      ),
    );
    await expectNoLayoutErrors(
      tester,
      () => AskQuestionModal(
        courseTags: const ['Flutter ile Mobil Uygulama Geliştirme (Uzun)'],
        topicSuggestions: const ['Bloc', 'Firebase', 'GoRouter'],
        onPickFromGallery: () async => null,
        onAskQuestion: ({required courseTag, required topicTag, required questionText, localPhotoPath}) async {},
      ),
      scrollable: false,
    );
  });
}

