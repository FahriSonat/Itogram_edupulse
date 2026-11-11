import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/features/assignments/data/models/assignment_model.dart';
import 'package:itogram_edupulse/features/assignments/domain/entities/assignment_entity.dart';

void main() {
  final DateTime dueDate = DateTime(2026, 11, 12, 23, 59);

  final AssignmentModel model = AssignmentModel(
    assignmentId: 'asg-1',
    courseId: 'course-101',
    courseName: 'Mobil Programlama',
    title: 'Flutter Ödevi',
    description: 'Clean Architecture ile bir ekran yapın.',
    rubricCriteria: 'Kod kalitesi: 50, Tasarım: 50',
    dueDate: dueDate,
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'courseId': 'course-101',
    'courseName': 'Mobil Programlama',
    'title': 'Flutter Ödevi',
    'description': 'Clean Architecture ile bir ekran yapın.',
    'rubricCriteria': 'Kod kalitesi: 50, Tasarım: 50',
    'dueDate': Timestamp.fromDate(dueDate),
  };

  group('AssignmentModel', () {
    test('AssignmentEntity alt sınıfıdır', () {
      expect(model, isA<AssignmentEntity>());
    });

    test('fromFirestore tüm alanları doğru okur', () {
      expect(AssignmentModel.fromFirestore(json, 'asg-1'), model);
    });

    test('toJson son teslim tarihini Timestamp olarak yazar', () {
      expect(model.toJson(), json);
      expect(model.toJson()['dueDate'], isA<Timestamp>());
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(
        AssignmentModel.fromFirestore(model.toJson(), model.assignmentId),
        model,
      );
    });

    test('son teslim tarihi dakika hassasiyetiyle korunur', () {
      final AssignmentModel parsed =
          AssignmentModel.fromFirestore(model.toJson(), model.assignmentId);
      expect(parsed.dueDate.isAtSameMomentAs(dueDate), isTrue);
    });

    test('copyWith sadece verilen alanı değiştirir', () {
      final DateTime newDue = dueDate.add(const Duration(days: 1));
      final AssignmentModel updated = model.copyWith(dueDate: newDue);
      expect(updated.dueDate, newDue);
      expect(updated.title, model.title);
      expect(updated.copyWith(dueDate: dueDate), model);
    });
  });
}
