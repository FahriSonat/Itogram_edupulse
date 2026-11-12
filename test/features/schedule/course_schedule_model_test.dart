import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/features/schedule/data/models/course_schedule_model.dart';
import 'package:itogram_edupulse/features/schedule/domain/entities/course_schedule_entity.dart';

void main() {
  const CourseScheduleModel model = CourseScheduleModel(
    courseId: 'course-101',
    courseCode: 'MOB101',
    courseName: 'Mobil Programlama',
    instructorName: 'Ad Soyad',
    roomLocation: 'D-107',
    dayOfWeek: 5,
    startTime: '09:00',
    endTime: '11:50',
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'courseCode': 'MOB101',
    'courseName': 'Mobil Programlama',
    'instructorName': 'Ad Soyad',
    'roomLocation': 'D-107',
    'dayOfWeek': 5,
    'startTime': '09:00',
    'endTime': '11:50',
  };

  group('CourseScheduleModel', () {
    test('CourseScheduleEntity alt sınıfıdır', () {
      expect(model, isA<CourseScheduleEntity>());
    });

    test('fromFirestore tüm alanları doğru okur', () {
      expect(CourseScheduleModel.fromFirestore(json, 'course-101'), model);
    });

    test('toJson doğru map üretir', () {
      expect(model.toJson(), json);
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(
        CourseScheduleModel.fromFirestore(model.toJson(), model.courseId),
        model,
      );
    });

    test('eğitmen amfiyi değiştirince yeni konum yazılır', () {
      final CourseScheduleModel moved = model.copyWith(roomLocation: 'A-201');
      expect(moved.toJson()['roomLocation'], 'A-201');
      expect(moved.courseName, model.courseName);
      expect(moved.copyWith(roomLocation: 'D-107'), model);
    });

    test('farklı derslerin eşitliği doğru ayrılır', () {
      expect(model == model.copyWith(dayOfWeek: 1), isFalse);
    });
  });
}
