import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/announcement_type.dart';
import 'package:itogram_edupulse/features/announcements/data/models/announcement_model.dart';
import 'package:itogram_edupulse/features/announcements/domain/entities/announcement_entity.dart';

void main() {
  final DateTime eventDate = DateTime(2026, 11, 13, 10);

  final AnnouncementModel model = AnnouncementModel(
    id: 'ann-1',
    title: 'Demo Day',
    content: 'Jüri sunumu 13 Kasım Cuma.',
    type: AnnouncementType.event,
    eventDate: eventDate,
    targetCourseId: 'course-101',
    authorName: 'Eğitmen',
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'title': 'Demo Day',
    'content': 'Jüri sunumu 13 Kasım Cuma.',
    'type': 'event',
    'eventDate': Timestamp.fromDate(eventDate),
    'targetCourseId': 'course-101',
    'authorName': 'Eğitmen',
  };

  group('AnnouncementModel', () {
    test('AnnouncementEntity alt sınıfıdır', () {
      expect(model, isA<AnnouncementEntity>());
    });

    test('fromFirestore tüm alanları doğru okur', () {
      expect(AnnouncementModel.fromFirestore(json, 'ann-1'), model);
    });

    test('toJson tarihi Timestamp olarak yazar', () {
      expect(model.toJson(), json);
      expect(model.toJson()['eventDate'], isA<Timestamp>());
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(AnnouncementModel.fromFirestore(model.toJson(), model.id), model);
    });

    test('tarih ve hedef ders yoksa null olur (tüm kampüs duyurusu)', () {
      final Map<String, dynamic> minimal = Map<String, dynamic>.of(json)
        ..remove('eventDate')
        ..remove('targetCourseId');
      final AnnouncementModel parsed =
          AnnouncementModel.fromFirestore(minimal, 'ann-1');
      expect(parsed.eventDate, isNull);
      expect(parsed.targetCourseId, isNull);
      expect(parsed.toJson()['eventDate'], isNull);
    });

    test('tüm duyuru türleri okunup yazılabilir', () {
      for (final AnnouncementType type in AnnouncementType.values) {
        final AnnouncementModel m = model.copyWith(type: type);
        expect(AnnouncementModel.fromFirestore(m.toJson(), m.id).type, type);
      }
    });

    test('bilinmeyen tür general olur', () {
      final Map<String, dynamic> bad = Map<String, dynamic>.of(json)
        ..['type'] = 'bilinmeyen';
      expect(
        AnnouncementModel.fromFirestore(bad, 'ann-1').type,
        AnnouncementType.general,
      );
    });

    test('copyWith sadece verilen alanı değiştirir', () {
      final AnnouncementModel updated = model.copyWith(title: 'Hackathon');
      expect(updated.title, 'Hackathon');
      expect(updated.content, model.content);
      expect(updated.copyWith(title: model.title), model);
    });
  });
}
