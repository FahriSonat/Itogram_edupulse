import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/constants/app_strings.dart';
import 'package:itogram_edupulse/core/enums/submission_status.dart';
import 'package:itogram_edupulse/features/assignments/presentation/widgets/assignment_countdown_card.dart';
import 'package:itogram_edupulse/features/assignments/presentation/widgets/audio_written_feedback_box.dart';
import 'package:itogram_edupulse/features/assignments/presentation/widgets/create_assignment_sheet.dart';
import 'package:itogram_edupulse/features/assignments/presentation/widgets/late_submission_warning_banner.dart';
import 'package:itogram_edupulse/features/assignments/presentation/widgets/storage_upload_progress_bar.dart';

import '../../helpers/design_test_harness.dart';

void main() {
  group('Kural 2 — GECİKMİŞ TESLİM (-10 Ceza Puanı)', () {
    test('rozet metni şartname metniyle birebir aynı', () {
      expect(LateSubmissionWarningBanner.badgeText(10), AppStrings.lateSubmissionBadge);
      expect(AppStrings.lateSubmissionBadge, 'GECİKMİŞ TESLİM (-10 Ceza Puanı)');
    });

    testWidgets('tam bant rozet + açıklama, kompakt mod yalnızca rozet gösterir', (tester) async {
      await pumpDesign(tester, const LateSubmissionWarningBanner());
      expect(find.text(AppStrings.lateSubmissionBadge), findsOneWidget);
      expect(find.text(AppStrings.lateSubmissionWarning), findsOneWidget);

      await pumpDesign(tester, const LateSubmissionWarningBanner.badge());
      expect(find.text(AppStrings.lateSubmissionBadge), findsOneWidget);
      expect(find.text(AppStrings.lateSubmissionWarning), findsNothing);
    });

    testWidgets('süresi geçmiş ödevde yükleme engellenmez: "Geç Teslim Et" + ceza rozeti', (tester) async {
      var pressed = false;
      final now = DateTime(2026, 11, 11, 12);
      await pumpDesign(
        tester,
        AssignmentCountdownCard(
          title: 'Clean Architecture',
          courseName: 'Flutter',
          description: 'Katmanlı mimari',
          dueDate: now.subtract(const Duration(days: 1)),
          now: now,
          onSubmitPressed: () => pressed = true,
        ),
      );
      expect(find.text(AppStrings.lateSubmissionBadge), findsOneWidget);
      await tester.tap(find.text('Geç Teslim Et'));
      expect(pressed, isTrue);
    });

    testWidgets('teslim edilmiş veya notlandırılmış ödevde yükleme butonu görünmez', (tester) async {
      final now = DateTime(2026, 11, 11, 12);
      for (final status in [SubmissionStatus.submitted, SubmissionStatus.graded]) {
        await pumpDesign(
          tester,
          AssignmentCountdownCard(
            title: 'Ödev',
            courseName: 'Flutter',
            description: '-',
            dueDate: now.add(const Duration(days: 3)),
            now: now,
            status: status,
            onSubmitPressed: () {},
          ),
        );
        expect(find.text(AppStrings.submissionStatus(status)), findsOneWidget);
        expect(find.text('Ödevi Yükle'), findsNothing);
        expect(find.text(AppStrings.lateSubmissionBadge), findsNothing);
      }
    });

    test('tüm teslim durumu etiketleri tanımlı', () {
      expect(SubmissionStatus.values.map(AppStrings.submissionStatus), [
        'Bekliyor',
        'Teslim Edildi',
        'Notlandırıldı',
        'Gecikti',
        'Eksik',
      ]);
    });
  });

  group('StorageUploadProgressBar', () {
    testWidgets('yükleme yüzdesini ve iptal butonunu birlikte gösterir', (tester) async {
      var cancelled = false;
      await pumpDesign(
        tester,
        StorageUploadProgressBar(progress: 0.42, fileName: 'odev.zip', onCancel: () => cancelled = true),
      );
      expect(find.text('%42'), findsOneWidget);
      await tester.tap(find.byTooltip('Yüklemeyi İptal Et'));
      expect(cancelled, isTrue);
    });

    testWidgets('tamamlandığında %100 ve hata mesajı gösterilir', (tester) async {
      await pumpDesign(
        tester,
        const StorageUploadProgressBar(progress: 1, fileName: 'a.pdf', isUploading: false, isCompleted: true),
      );
      expect(find.text('%100'), findsOneWidget);

      await pumpDesign(
        tester,
        const StorageUploadProgressBar(progress: 0.3, fileName: 'a.pdf', errorMessage: 'Dosya 25 MB sınırını aşıyor'),
      );
      expect(find.text('Dosya 25 MB sınırını aşıyor'), findsOneWidget);
    });
  });

  group('CreateAssignmentSheet', () {
    testWidgets('ders kimliği, rubrik ve son tarih ile ödev yayınlar', (tester) async {
      Map<String, Object>? created;
      await pumpDesign(
        tester,
        CreateAssignmentSheet(
          courses: const {'c101': 'Flutter ile Mobil', 'c202': 'Veri Yapıları'},
          initialDueDate: DateTime(2026, 11, 20, 23, 59),
          onCreate:
              ({
                required courseId,
                required courseName,
                required title,
                required description,
                required rubricCriteria,
                required dueDate,
              }) async {
                created = {
                  'courseId': courseId,
                  'courseName': courseName,
                  'title': title,
                  'rubric': rubricCriteria,
                  'due': dueDate,
                };
              },
        ),
        scrollable: false,
      );
      expect(find.text('20.11.2026 - 23:59'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('assignment_title_field')), 'BLoC Projesi');
      await tester.enterText(find.byKey(const ValueKey('assignment_description_field')), 'Cubit ile durum yönetimi');
      await tester.tap(find.text('Kod Kalitesi (%40)'));
      await tester.pump();
      await tester.ensureVisible(find.text('Ödevi Öğrencilere Yayınla'));
      await tester.tap(find.text('Ödevi Öğrencilere Yayınla'));
      await tester.pump();

      expect(created, isNotNull);
      expect(created!['courseId'], 'c101');
      expect(created!['courseName'], 'Flutter ile Mobil');
      expect(created!['title'], 'BLoC Projesi');
      expect(created!['rubric'], 'Kod Kalitesi (%40)');
      expect(created!['due'], DateTime(2026, 11, 20, 23, 59));
    });

    testWidgets('zorunlu alanlar boşken yayınlamaz', (tester) async {
      var called = false;
      await pumpDesign(
        tester,
        CreateAssignmentSheet(
          courses: const {'c101': 'Flutter'},
          onCreate: ({
            required courseId,
            required courseName,
            required title,
            required description,
            required rubricCriteria,
            required dueDate,
          }) async => called = true,
        ),
        scrollable: false,
      );
      await tester.ensureVisible(find.text('Ödevi Öğrencilere Yayınla'));
      await tester.tap(find.text('Ödevi Öğrencilere Yayınla'));
      await tester.pump();
      expect(called, isFalse);
      expect(find.text('Başlık zorunludur'), findsOneWidget);
    });
  });

  group('AudioWrittenFeedbackBox', () {
    testWidgets('eğitmen yazılı geribildirim girer ve ses kaydı başlatır', (tester) async {
      String? feedback;
      var recording = false;
      await pumpDesign(
        tester,
        AudioWrittenFeedbackBox(
          isInstructor: true,
          onWrittenFeedbackChanged: (v) => feedback = v,
          onStartRecording: () => recording = true,
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('written_feedback_field')), 'Harika iş!');
      expect(feedback, 'Harika iş!');
      await tester.tap(find.byTooltip('Ses Kaydı Başlat'));
      expect(recording, isTrue);
    });

    testWidgets('öğrenci sesli notu dinler, kayıt yoksa oynatma pasif', (tester) async {
      var played = false;
      await pumpDesign(
        tester,
        AudioWrittenFeedbackBox(
          writtenFeedback: 'Rubriğe uygun.',
          audioFeedbackUrl: 'https://example.com/a.m4a',
          audioDurationLabel: '0:45',
          onPlayAudio: () => played = true,
        ),
      );
      expect(find.text('Rubriğe uygun.'), findsOneWidget);
      expect(find.text('0:45 • Dinlemek için dokunun'), findsOneWidget);
      expect(find.byTooltip('Ses Kaydı Başlat'), findsNothing);
      await tester.tap(find.byTooltip('Sesli notu dinle'));
      expect(played, isTrue);

      await pumpDesign(tester, const AudioWrittenFeedbackBox());
      expect(find.text('Sesli not eklenmemiş'), findsOneWidget);
    });
  });

  testWidgets('ödev bileşenleri hiçbir ekran koşulunda taşmaz', (tester) async {
    final now = DateTime(2026, 11, 11);
    await expectNoLayoutErrors(
      tester,
      () => AssignmentCountdownCard(
        title: 'Çok uzun bir ödev başlığı: Clean Architecture ile kurumsal mobil uygulama',
        courseName: 'İleri Seviye Mobil Uygulama Geliştirme ve Mimari',
        description: 'Açıklama metni ' * 10,
        dueDate: now.subtract(const Duration(hours: 2)),
        now: now,
        status: SubmissionStatus.late,
        onSubmitPressed: () {},
      ),
    );
    await expectNoLayoutErrors(tester, () => const LateSubmissionWarningBanner());
    await expectNoLayoutErrors(
      tester,
      () => StorageUploadProgressBar(progress: 0.5, fileName: 'cok_uzun_dosya_adi_' * 6, onCancel: () {}),
    );
    await expectNoLayoutErrors(
      tester,
      () => AudioWrittenFeedbackBox(isInstructor: true, isRecording: true, onStopRecording: () {}),
    );
    await expectNoLayoutErrors(
      tester,
      () => CreateAssignmentSheet(
        courses: const {'c1': 'Flutter ile Mobil Uygulama Geliştirme (Uzun Ders Adı)'},
        onCreate: ({
          required courseId,
          required courseName,
          required title,
          required description,
          required rubricCriteria,
          required dueDate,
        }) async {},
      ),
      scrollable: false,
    );
  });
}

