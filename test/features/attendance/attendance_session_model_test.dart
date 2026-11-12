import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/attendance_status.dart';
import 'package:itogram_edupulse/features/attendance/data/models/attendance_session_model.dart';
import 'package:itogram_edupulse/features/attendance/domain/entities/attendance_session_entity.dart';

void main() {
  final DateTime createdAt = DateTime(2026, 11, 13, 9);
  final DateTime expiresAt = createdAt.add(const Duration(seconds: 60));

  final AttendanceSessionModel model = AttendanceSessionModel(
    sessionId: 'sess-1',
    courseId: 'course-101',
    qrCodeToken: 'qr-token-xyz',
    pinCode: '4821',
    createdAt: createdAt,
    expiresAt: expiresAt,
    isActive: true,
    studentStatusMap: const <String, AttendanceStatus>{
      'uid-1': AttendanceStatus.present,
      'uid-2': AttendanceStatus.absent,
      'uid-3': AttendanceStatus.excused,
    },
  );

  final Map<String, dynamic> json = <String, dynamic>{
    'courseId': 'course-101',
    'qrCodeToken': 'qr-token-xyz',
    'pinCode': '4821',
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'isActive': true,
    'studentStatusMap': <String, dynamic>{
      'uid-1': 'present',
      'uid-2': 'absent',
      'uid-3': 'excused',
    },
  };

  group('AttendanceSessionModel', () {
    test('AttendanceSessionEntity alt sınıfıdır', () {
      expect(model, isA<AttendanceSessionEntity>());
    });

    test('fromFirestore tüm alanları ve durum haritasını doğru okur', () {
      expect(AttendanceSessionModel.fromFirestore(json, 'sess-1'), model);
    });

    test('toJson durum haritasını string olarak yazar', () {
      expect(model.toJson(), json);
    });

    test('toJson -> fromFirestore aynı nesneyi verir', () {
      expect(
        AttendanceSessionModel.fromFirestore(model.toJson(), model.sessionId),
        model,
      );
    });

    test('Kural 1: expiresAt, createdAt + 60 saniye olarak korunur', () {
      final AttendanceSessionModel parsed =
          AttendanceSessionModel.fromFirestore(model.toJson(), model.sessionId);
      expect(parsed.expiresAt.difference(parsed.createdAt).inSeconds, 60);
    });

    test('PIN baştaki sıfırı kaybetmez (string olarak saklanır)', () {
      final AttendanceSessionModel m = model.copyWith(pinCode: '0042');
      expect(
        AttendanceSessionModel.fromFirestore(m.toJson(), m.sessionId).pinCode,
        '0042',
      );
    });

    test('durum haritası yoksa boş harita olur', () {
      final Map<String, dynamic> noMap = Map<String, dynamic>.of(json)
        ..remove('studentStatusMap');
      expect(
        AttendanceSessionModel.fromFirestore(noMap, 'sess-1').studentStatusMap,
        isEmpty,
      );
    });

    test('bilinmeyen öğrenci durumu absent sayılır', () {
      final Map<String, dynamic> bad = Map<String, dynamic>.of(json)
        ..['studentStatusMap'] = <String, dynamic>{'uid-9': 'bilinmeyen'};
      expect(
        AttendanceSessionModel.fromFirestore(bad, 'sess-1')
            .studentStatusMap['uid-9'],
        AttendanceStatus.absent,
      );
    });

    test('isActive yoksa false olur (kapalı oturum)', () {
      final Map<String, dynamic> noActive = Map<String, dynamic>.of(json)
        ..remove('isActive');
      expect(
        AttendanceSessionModel.fromFirestore(noActive, 'sess-1').isActive,
        isFalse,
      );
    });

    test('copyWith sadece verilen alanı değiştirir', () {
      final AttendanceSessionModel closed = model.copyWith(isActive: false);
      expect(closed.isActive, isFalse);
      expect(closed.pinCode, model.pinCode);
      expect(closed.copyWith(isActive: true), model);
    });
  });
}
