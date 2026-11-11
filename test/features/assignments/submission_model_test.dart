import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/submission_status.dart';
import 'package:itogram_edupulse/features/assignments/data/models/submission_model.dart';
import 'package:itogram_edupulse/features/assignments/domain/entities/submission_entity.dart';

void main() {
  final DateTime submittedAt = DateTime(2026, 11, 13, 9, 30);

  final SubmissionModel model = SubmissionModel(
    submissionId: 'sub-1',
    assignmentId: 'asg-1',
    studentUid: 'uid-1',
    studentName: 'Merve Kedersiz',
    fileUrl: 'https://storage.example.com/odev.pdf',
    fileName: 'odev.pdf',
    submittedAt: submittedAt,
    status: SubmissionStatus.late,
    isLatePenaltyApplied: true,
    rawScore: 90,
    finalScore: 80,
    writtenFeedback: 'İyi iş, ama geç teslim.',
    audioFeedbackUrl: 'https://storage.example.com/ses.m4a',
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'assignmentId': 'asg-1',
    'studentUid': 'uid-1',
    'studentName': 'Merve Kedersiz',
    'fileUrl': 'https://storage.example.com/odev.pdf',
    'fileName': 'odev.pdf',
    'submittedAt': Timestamp.fromDate(submittedAt),
    'status': 'late',
    'isLatePenaltyApplied': true,
    'rawScore': 90.0,
    'finalScore': 80.0,
    'writtenFeedback': 'İyi iş, ama geç teslim.',
    'audioFeedbackUrl': 'https://storage.example.com/ses.m4a',
  };

  group('SubmissionModel', () {
    test('SubmissionEntity alt sınıfıdır', () {
      expect(model, isA<SubmissionEntity>());
    });

    test('fromFirestore tüm alanları doğru okur', () {
      expect(SubmissionModel.fromFirestore(json, 'sub-1'), model);
    });

    test('toJson doğru map üretir', () {
      expect(model.toJson(), json);
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(
        SubmissionModel.fromFirestore(model.toJson(), model.submissionId),
        model,
      );
    });

    test('Kural 2: gecikme ceza bayrağı (-10) korunur', () {
      final SubmissionModel parsed =
          SubmissionModel.fromFirestore(model.toJson(), model.submissionId);
      expect(parsed.status, SubmissionStatus.late);
      expect(parsed.isLatePenaltyApplied, isTrue);
    });

    test('Firestore int puan döndürse de double olarak okunur', () {
      final Map<String, dynamic> intScores = Map<String, dynamic>.of(json)
        ..['rawScore'] = 90
        ..['finalScore'] = 80;
      final SubmissionModel parsed =
          SubmissionModel.fromFirestore(intScores, 'sub-1');
      expect(parsed.rawScore, 90.0);
      expect(parsed.finalScore, 80.0);
    });

    test('henüz notlanmamış teslimde puan ve geribildirim null olur', () {
      final Map<String, dynamic> ungraded = Map<String, dynamic>.of(json)
        ..remove('rawScore')
        ..remove('finalScore')
        ..remove('writtenFeedback')
        ..remove('audioFeedbackUrl')
        ..remove('isLatePenaltyApplied')
        ..['status'] = 'submitted';
      final SubmissionModel parsed =
          SubmissionModel.fromFirestore(ungraded, 'sub-1');
      expect(parsed.rawScore, isNull);
      expect(parsed.finalScore, isNull);
      expect(parsed.writtenFeedback, isNull);
      expect(parsed.audioFeedbackUrl, isNull);
      expect(parsed.isLatePenaltyApplied, isFalse);
      expect(parsed.status, SubmissionStatus.submitted);
    });

    test('bilinmeyen durum pending olur', () {
      final Map<String, dynamic> bad = Map<String, dynamic>.of(json)
        ..['status'] = 'bilinmeyen';
      expect(
        SubmissionModel.fromFirestore(bad, 'sub-1').status,
        SubmissionStatus.pending,
      );
    });

    test('tüm teslim durumları okunup yazılabilir', () {
      for (final SubmissionStatus status in SubmissionStatus.values) {
        final SubmissionModel m = model.copyWith(status: status);
        expect(
          SubmissionModel.fromFirestore(m.toJson(), m.submissionId).status,
          status,
        );
      }
    });

    test('copyWith sadece verilen alanı değiştirir', () {
      final SubmissionModel updated = model.copyWith(finalScore: 75);
      expect(updated.finalScore, 75);
      expect(updated.rawScore, model.rawScore);
      expect(updated.copyWith(finalScore: model.finalScore), model);
    });
  });
}
