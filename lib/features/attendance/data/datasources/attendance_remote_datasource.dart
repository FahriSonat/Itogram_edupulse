import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/attendance_status.dart';

/// Kritik İş Kuralı 1: 60 saniyelik QR/PIN yoklama oturumu süresi dolduğunda
/// veya oturum kapalı olduğunda fırlatılan özel istisna.
class ExpiredQrPinException implements Exception {
  final String message;

  const ExpiredQrPinException([
    this.message = 'Yoklama kodunun 60 saniyelik süresi dolmuş veya oturum kapatılmış.',
  ]);

  @override
  String toString() => message;
}

/// Kritik İş Kuralı 1 & 3 Uygulayıcısı:
/// 1) Öğrenci PIN veya QR okuttuğunda Firestore Transaction içinde sunucu zamanını
///    kontrol eder; `now > expiresAt` (60 sn dolmuşsa) veya oturum kapalıysa
///    [ExpiredQrPinException] fırlatır.
/// 2) Eğitmen yoklamayı kapattığında veya manuel devamsızlık eklediğinde öğrencinin
///    toplam devamsızlık yüzdesini hesaplar; %20'yi aşıyorsa `isCriticalRisk = true` yapar.
abstract class AttendanceRemoteDataSource {
  Future<Map<String, dynamic>> createOrRefresh60sQrPinSession({
    required String courseId,
    required String instructorId,
    String? sessionId,
    int validitySeconds = 60,
  });

  Future<Map<String, dynamic>> submitLiveAttendance({
    required String courseId,
    required String sessionId,
    required String studentId,
    required String studentName,
    required String studentNo,
    String? pinOrQrToken,
  });

  /// Eğitmen yoklama oturumunu kapattığında katılmayan öğrencilerin devamsızlığını
  /// günceller ve %20 sınırını aşan kritik riskli öğrencilerin listesini döner.
  Future<List<Map<String, dynamic>>> closeAttendanceSession({
    required String courseId,
    required String sessionId,
    int sessionHours = 1,
    int totalCourseHours = 14,
  });

  Stream<Map<String, dynamic>?> watchLiveAttendanceSession({
    required String courseId,
    required String sessionId,
  });

  Stream<List<Map<String, dynamic>>> watchCourseAttendanceRecords({
    required String courseId,
  });

  Future<Map<String, dynamic>> updateStudentAttendanceRecord({
    required String courseId,
    required String studentId,
    required String studentName,
    required String studentNo,
    required AttendanceStatus status,
    required int totalSessions,
    required int absentHours,
    required int maxAllowedAbsentHours,
  });
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Random _random = Random.secure();

  AttendanceRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionsRef(String courseId) =>
      _firestore.collection(FirestorePaths.attendanceSessions(courseId));

  CollectionReference<Map<String, dynamic>> _recordsRef(String courseId) =>
      _firestore.collection(FirestorePaths.attendanceRecords(courseId));

  String _generate6DigitPin() {
    final number = 100000 + _random.nextInt(900000);
    return number.toString();
  }

  @override
  Future<Map<String, dynamic>> createOrRefresh60sQrPinSession({
    required String courseId,
    required String instructorId,
    String? sessionId,
    int validitySeconds = 60,
  }) async {
    final sessionsCol = _sessionsRef(courseId);
    final docRef =
        sessionId != null ? sessionsCol.doc(sessionId) : sessionsCol.doc();

    final now = DateTime.now();
    final expiresAt = now.add(Duration(seconds: validitySeconds));
    final pinCode = _generate6DigitPin();
    final qrPayload =
        'EDUPULSE|$courseId|${docRef.id}|$pinCode|${expiresAt.millisecondsSinceEpoch}';

    final payload = <String, dynamic>{
      'id': docRef.id,
      'courseId': courseId,
      'instructorId': instructorId,
      'pinCode': pinCode,
      'qrData': qrPayload,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };

    if (sessionId == null) {
      payload['presentStudentIds'] = <String>[];
      payload['attendees'] = <Map<String, dynamic>>[];
      await docRef.set(payload);
    } else {
      await docRef.set(payload, SetOptions(merge: true));
    }

    return _normalizeMap(payload);
  }

  @override
  Future<Map<String, dynamic>> submitLiveAttendance({
    required String courseId,
    required String sessionId,
    required String studentId,
    required String studentName,
    required String studentNo,
    String? pinOrQrToken,
  }) async {
    final sessionDocRef = _sessionsRef(courseId).doc(sessionId);
    final recordDocRef = _recordsRef(courseId).doc(studentId);

    return _firestore.runTransaction((transaction) async {
      final sessionSnap = await transaction.get(sessionDocRef);
      if (!sessionSnap.exists || sessionSnap.data() == null) {
        throw const ExpiredQrPinException('Yoklama oturumu bulunamadı.');
      }

      final sessionData = sessionSnap.data()!;
      final isActive = sessionData['isActive'] as bool? ?? false;
      final expiresAtRaw = sessionData['expiresAt'];
      final expiresAt = expiresAtRaw is Timestamp
          ? expiresAtRaw.toDate()
          : DateTime.tryParse(expiresAtRaw?.toString() ?? '');

      final now = DateTime.now();

      // Kritik İş Kuralı 1: now > expiresAt (60 sn dolmuşsa) veya oturum kapalıysa ExpiredQrPinException fırlat
      if (!isActive || (expiresAt != null && now.isAfter(expiresAt))) {
        throw const ExpiredQrPinException(
          'Yoklama kodunun 60 saniyelik süresi doldu veya oturum kapatıldı.',
        );
      }

      if (pinOrQrToken != null && pinOrQrToken.trim().isNotEmpty) {
        final expectedPin = sessionData['pinCode']?.toString();
        final expectedQr = sessionData['qrData']?.toString();
        final trimmedInput = pinOrQrToken.trim();
        if (trimmedInput != expectedPin && trimmedInput != expectedQr) {
          throw Exception('Geçersiz PIN veya QR kodu.');
        }
      }

      final attendeeEntry = <String, dynamic>{
        'studentId': studentId,
        'studentName': studentName,
        'studentNo': studentNo,
        'status': AttendanceStatus.present.name,
        'timestamp': now.toIso8601String(),
      };

      transaction.update(sessionDocRef, {
        'presentStudentIds': FieldValue.arrayUnion([studentId]),
        'attendees': FieldValue.arrayUnion([attendeeEntry]),
      });

      final recordSnap = await transaction.get(recordDocRef);
      if (recordSnap.exists && recordSnap.data() != null) {
        final currentAttended =
            (recordSnap.data()!['attendedSessions'] as int?) ?? 0;
        transaction.update(recordDocRef, {
          'attendedSessions': currentAttended + 1,
          'lastStatus': AttendanceStatus.present.name,
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        transaction.set(recordDocRef, {
          'id': studentId,
          'courseId': courseId,
          'studentId': studentId,
          'studentName': studentName,
          'studentNo': studentNo,
          'attendedSessions': 1,
          'absentHours': 0,
          'maxAllowedAbsentHours': 14,
          'absencePercentage': 0.0,
          'isCriticalRisk': false,
          'lastStatus': AttendanceStatus.present.name,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      return attendeeEntry;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> closeAttendanceSession({
    required String courseId,
    required String sessionId,
    int sessionHours = 1,
    int totalCourseHours = 14,
  }) async {
    final sessionDocRef = _sessionsRef(courseId).doc(sessionId);
    final sessionSnap = await sessionDocRef.get();
    final presentIds = List<String>.from(
      sessionSnap.data()?['presentStudentIds'] as List? ?? const [],
    );

    await sessionDocRef.set(
      {
        'isActive': false,
        'closedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );

    final recordsSnap = await _recordsRef(courseId).get();
    final batch = _firestore.batch();
    final criticalStudents = <Map<String, dynamic>>[];

    for (final doc in recordsSnap.docs) {
      final data = doc.data();
      final studentId = (data['studentId'] ?? doc.id).toString();
      if (!presentIds.contains(studentId)) {
        final currentAbsent = (data['absentHours'] as int?) ?? 0;
        final newAbsent = currentAbsent + sessionHours;
        final totalHours = (data['totalSessions'] as int?) ?? totalCourseHours;
        final effectiveTotal = totalHours > 0 ? totalHours : 14;
        final absencePercentage = newAbsent / effectiveTotal;
        final isCriticalRisk = absencePercentage > 0.20;

        final updatedData = <String, dynamic>{
          ...data,
          'id': doc.id,
          'absentHours': newAbsent,
          'absencePercentage': absencePercentage,
          'isCriticalRisk': isCriticalRisk,
          'lastStatus': AttendanceStatus.absent.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        batch.set(doc.reference, updatedData, SetOptions(merge: true));
        if (isCriticalRisk) {
          criticalStudents.add(_normalizeMap(updatedData));
        }
      }
    }

    await batch.commit();
    return criticalStudents;
  }

  @override
  Stream<Map<String, dynamic>?> watchLiveAttendanceSession({
    required String courseId,
    required String sessionId,
  }) {
    return _sessionsRef(courseId).doc(sessionId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      return _normalizeMap(data);
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCourseAttendanceRecords({
    required String courseId,
  }) {
    return _recordsRef(courseId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _normalizeMap(data);
      }).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> updateStudentAttendanceRecord({
    required String courseId,
    required String studentId,
    required String studentName,
    required String studentNo,
    required AttendanceStatus status,
    required int totalSessions,
    required int absentHours,
    required int maxAllowedAbsentHours,
  }) async {
    final effectiveTotal =
        totalSessions > 0 ? totalSessions : (maxAllowedAbsentHours * 5);
    final absencePercentage =
        effectiveTotal > 0 ? (absentHours / effectiveTotal) : 0.0;

    // Kritik İş Kuralı 3: Devamsızlık yüzdesi %20'yi aşıyorsa isCriticalRisk = true
    final isCriticalRisk = absencePercentage > 0.20 ||
        (maxAllowedAbsentHours > 0 && absentHours > maxAllowedAbsentHours);

    final payload = <String, dynamic>{
      'id': studentId,
      'courseId': courseId,
      'studentId': studentId,
      'studentName': studentName,
      'studentNo': studentNo,
      'lastStatus': status.name,
      'totalSessions': totalSessions,
      'absentHours': absentHours,
      'maxAllowedAbsentHours': maxAllowedAbsentHours,
      'absencePercentage': absencePercentage,
      'isCriticalRisk': isCriticalRisk,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await _recordsRef(courseId).doc(studentId).set(
          payload,
          SetOptions(merge: true),
        );

    return _normalizeMap(payload);
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}
