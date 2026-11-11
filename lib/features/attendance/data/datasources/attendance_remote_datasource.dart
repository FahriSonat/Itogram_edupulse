import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/enums/user_role.dart';
import '../models/attendance_session_model.dart';
import '../models/student_absence_record_model.dart';

/// Kritik İş Kuralı 1: 60 saniyelik QR/PIN yoklama oturumu süresi dolduğunda
/// veya oturum kapalı olduğunda fırlatılan özel istisna.
class ExpiredQrPinException implements Exception {
  final String message;

  const ExpiredQrPinException([
    this.message =
        'Yoklama kodunun 60 saniyelik süresi dolmuş veya oturum kapatılmış.',
  ]);

  @override
  String toString() => message;
}

abstract class AttendanceRemoteDataSource {
  Future<AttendanceSessionModel> generateAttendanceSession(String courseId);

  Future<void> submitLiveAttendance({
    required String sessionId,
    required String studentUid,
    required String code,
  });

  Stream<AttendanceSessionModel?> watchLiveAttendanceRoster(String sessionId);

  Future<StudentAbsenceRecordModel> updateAttendanceRecord({
    required String courseId,
    required String studentUid,
    required AttendanceStatus status,
  });

  Future<StudentAbsenceRecordModel> evaluateAbsenceRisk(
    String courseId,
    String studentUid,
  );

  Stream<List<StudentAbsenceRecordModel>> watchClassAbsenceRecords(
    String courseId,
  );

  Future<StudentAbsenceRecordModel> getStudentAbsenceRecord(
    String courseId,
    String studentUid,
  );
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  static const int defaultTotalCourseHours = 14;

  final FirebaseFirestore _firestore;
  final Random _random = Random.secure();
  final Map<String, String> _sessionCourseCache = <String, String>{};

  AttendanceRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionsRef(String courseId) =>
      _firestore.collection(FirestorePaths.attendanceSessions(courseId));

  CollectionReference<Map<String, dynamic>> _recordsRef(String courseId) =>
      _firestore.collection(FirestorePaths.attendanceRecords(courseId));

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(FirestorePaths.users);

  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection(FirestorePaths.courses);

  /// Şartnameye uygun 4 haneli PIN (1000 - 9999) üretir.
  String _generate4DigitPin() {
    final number = 1000 + _random.nextInt(9000);
    return number.toString();
  }

  /// Hiç yoklama vermemiş öğrenciler için de `attendance_records` başlangıç
  /// dökümanlarının (`StudentAbsenceRecordModel` şemasında) var olduğundan emin olur.
  Future<Map<String, AttendanceStatus>> _initializeCourseAttendanceRecords(
    String courseId,
  ) async {
    final initialStatusMap = <String, AttendanceStatus>{};

    try {
      final courseDoc = await _coursesRef.doc(courseId).get();
      final courseName =
          (courseDoc.data()?['courseName'] ?? courseId).toString();

      final existingRecordsSnap = await _recordsRef(courseId).get();
      final existingIds =
          existingRecordsSnap.docs.map((doc) => doc.id).toSet();

      final studentsSnap = await _usersRef
          .where('role', isEqualTo: UserRole.student.name)
          .get();

      final batch = _firestore.batch();
      var hasNewRecord = false;

      for (final studentDoc in studentsSnap.docs) {
        final studentUid = studentDoc.id;
        initialStatusMap[studentUid] = AttendanceStatus.absent;

        if (!existingIds.contains(studentUid)) {
          final sData = studentDoc.data();
          final studentName = (sData['fullName'] ?? '').toString();
          final studentNo =
              (sData['studentOrStaffNo'] ?? sData['studentNo'] ?? '').toString();

          final recordModel = StudentAbsenceRecordModel(
            studentUid: studentUid,
            studentName: studentName,
            studentNo: studentNo,
            courseId: courseId,
            courseName: courseName,
            totalCourseHours: defaultTotalCourseHours,
            absentHours: 0,
            absencePercentage: 0.0,
            isCriticalRisk: false,
          );

          batch.set(
            _recordsRef(courseId).doc(studentUid),
            recordModel.toJson(),
          );
          hasNewRecord = true;
        }
      }

      if (hasNewRecord) {
        await batch.commit();
      }
    } catch (_) {
      // Öğrenci rolüyle çağrıldığında yazma izni yoksa sessizce geç
    }

    return initialStatusMap;
  }

  /// `sessionId` veya `code` üzerinden ilgili oturumun Firestore döküman referansını
  /// ve `courseId` bilgisini çözümler.
  Future<DocumentReference<Map<String, dynamic>>> _resolveSessionDocRef({
    required String sessionId,
    String? code,
  }) async {
    // 1) QR token içinden courseId ve sessionId ayrıştırma: EDUPULSE|courseId|sessionId|pinCode
    if (code != null && code.startsWith('EDUPULSE|')) {
      final parts = code.split('|');
      if (parts.length >= 3) {
        final parsedCourseId = parts[1];
        final parsedSessionId = parts[2];
        _sessionCourseCache[parsedSessionId] = parsedCourseId;
        return _sessionsRef(parsedCourseId).doc(parsedSessionId);
      }
    }

    // 2) sessionId "courseId/sessionId" formatındaysa
    if (sessionId.contains('/')) {
      final parts = sessionId.split('/');
      if (parts.length >= 2) {
        _sessionCourseCache[parts.last] = parts.first;
        return _sessionsRef(parts.first).doc(parts.last);
      }
    }

    // 3) Önbellekte courseId varsa
    final cachedCourseId = _sessionCourseCache[sessionId];
    if (cachedCourseId != null && cachedCourseId.isNotEmpty) {
      return _sessionsRef(cachedCourseId).doc(sessionId);
    }

    // 4) Courses koleksiyonundaki alt koleksiyonlardan bul
    final coursesSnap = await _coursesRef.get();
    for (final courseDoc in coursesSnap.docs) {
      final cId = courseDoc.id;
      if (sessionId.isNotEmpty) {
        final candidateRef = _sessionsRef(cId).doc(sessionId);
        final candidateSnap = await candidateRef.get();
        if (candidateSnap.exists) {
          _sessionCourseCache[sessionId] = cId;
          return candidateRef;
        }
      }

      if (code != null && code.trim().isNotEmpty) {
        final byPinSnap = await _sessionsRef(cId)
            .where('pinCode', isEqualTo: code.trim())
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
        if (byPinSnap.docs.isNotEmpty) {
          final foundDoc = byPinSnap.docs.first;
          _sessionCourseCache[foundDoc.id] = cId;
          return foundDoc.reference;
        }
      }
    }

    // 5) Eğer sessionId doğrudan courseId olarak verilmişse o dersteki aktif oturumu bul
    if (sessionId.isNotEmpty) {
      final activeInCourse = await _sessionsRef(sessionId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (activeInCourse.docs.isNotEmpty) {
        final foundDoc = activeInCourse.docs.first;
        _sessionCourseCache[foundDoc.id] = sessionId;
        return foundDoc.reference;
      }
    }

    throw const ExpiredQrPinException('Aktif yoklama oturumu bulunamadı.');
  }

  @override
  Future<AttendanceSessionModel> generateAttendanceSession(
    String courseId,
  ) async {
    final initialStatusMap = await _initializeCourseAttendanceRecords(courseId);
    final docRef = _sessionsRef(courseId).doc();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(seconds: 60));
    final pinCode = _generate4DigitPin();
    final qrCodeToken =
        'EDUPULSE|$courseId|${docRef.id}|$pinCode|${expiresAt.millisecondsSinceEpoch}';

    final sessionModel = AttendanceSessionModel(
      sessionId: docRef.id,
      courseId: courseId,
      qrCodeToken: qrCodeToken,
      pinCode: pinCode,
      createdAt: now,
      expiresAt: expiresAt,
      isActive: true,
      studentStatusMap: initialStatusMap,
    );

    _sessionCourseCache[docRef.id] = courseId;
    await docRef.set(sessionModel.toJson());
    return sessionModel;
  }

  @override
  Future<void> submitLiveAttendance({
    required String sessionId,
    required String studentUid,
    required String code,
  }) async {
    final sessionDocRef = await _resolveSessionDocRef(
      sessionId: sessionId,
      code: code,
    );
    final courseId =
        sessionDocRef.parent.parent?.id ?? _sessionCourseCache[sessionId] ?? '';
    final recordDocRef = _recordsRef(courseId).doc(studentUid);
    final userDocRef = _usersRef.doc(studentUid);
    final courseDocRef = _coursesRef.doc(courseId);

    await _firestore.runTransaction((transaction) async {
      // =======================================================================
      // 1) ÖNCE TÜM OKUMALAR (Firestore Transaction Kuralı: Reads before Writes)
      // =======================================================================
      final sessionSnap = await transaction.get(sessionDocRef);
      final recordSnap = await transaction.get(recordDocRef);
      final userSnap = await transaction.get(userDocRef);
      final courseSnap = await transaction.get(courseDocRef);

      if (!sessionSnap.exists || sessionSnap.data() == null) {
        throw const ExpiredQrPinException('Yoklama oturumu bulunamadı.');
      }

      final sessionData = sessionSnap.data()!;
      final isActive = sessionData['isActive'] as bool? ?? false;
      final expiresAt = (sessionData['expiresAt'] as Timestamp).toDate();
      final now = DateTime.now();

      // Kritik İş Kuralı 1: now > expiresAt (60 sn dolmuşsa) veya oturum kapalıysa ExpiredQrPinException
      if (!isActive || now.isAfter(expiresAt)) {
        throw const ExpiredQrPinException(
          'Yoklama kodunun 60 saniyelik süresi doldu veya oturum kapatıldı.',
        );
      }

      final expectedPin = (sessionData['pinCode'] ?? '').toString().trim();
      final expectedQr = (sessionData['qrCodeToken'] ?? '').toString().trim();
      final trimmedCode = code.trim();

      // Boş kod asla kabul edilmez (aksi halde kod girmeden yoklama verilirdi).
      if (trimmedCode.isEmpty ||
          (trimmedCode != expectedPin && trimmedCode != expectedQr)) {
        throw Exception('Geçersiz PIN veya QR kodu.');
      }

      // =======================================================================
      // 2) SONRA TÜM YAZMALAR
      // =======================================================================
      final currentStatusMap = Map<String, dynamic>.from(
        sessionData['studentStatusMap'] as Map<String, dynamic>? ?? {},
      );
      currentStatusMap[studentUid] = AttendanceStatus.present.name;

      transaction.update(sessionDocRef, {
        'studentStatusMap': currentStatusMap,
      });

      if (!recordSnap.exists || recordSnap.data() == null) {
        final userData = userSnap.data() ?? const <String, dynamic>{};
        final courseData = courseSnap.data() ?? const <String, dynamic>{};
        final newRecord = StudentAbsenceRecordModel(
          studentUid: studentUid,
          studentName: (userData['fullName'] ?? '').toString(),
          studentNo:
              (userData['studentOrStaffNo'] ?? userData['studentNo'] ?? '')
                  .toString(),
          courseId: courseId,
          courseName: (courseData['courseName'] ?? courseId).toString(),
          totalCourseHours: defaultTotalCourseHours,
          absentHours: 0,
          absencePercentage: 0.0,
          isCriticalRisk: false,
        );
        transaction.set(recordDocRef, newRecord.toJson());
      }
    });
  }

  @override
  Stream<AttendanceSessionModel?> watchLiveAttendanceRoster(
    String sessionId,
  ) async* {
    final sessionDocRef = await _resolveSessionDocRef(sessionId: sessionId);
    yield* sessionDocRef.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AttendanceSessionModel.fromFirestore(doc.data()!, doc.id);
    });
  }

  @override
  Future<StudentAbsenceRecordModel> updateAttendanceRecord({
    required String courseId,
    required String studentUid,
    required AttendanceStatus status,
  }) async {
    final recordDocRef = _recordsRef(courseId).doc(studentUid);
    final recordSnap = await recordDocRef.get();

    int totalCourseHours = defaultTotalCourseHours;
    int absentHours = 0;
    String studentName = '';
    String studentNo = '';
    String courseName = courseId;

    if (recordSnap.exists && recordSnap.data() != null) {
      final existing = StudentAbsenceRecordModel.fromFirestore(
        recordSnap.data()!,
        recordSnap.id,
      );
      totalCourseHours = existing.totalCourseHours > 0
          ? existing.totalCourseHours
          : defaultTotalCourseHours;
      absentHours = existing.absentHours;
      studentName = existing.studentName;
      studentNo = existing.studentNo;
      courseName = existing.courseName;
    } else {
      final userSnap = await _usersRef.doc(studentUid).get();
      final courseSnap = await _coursesRef.doc(courseId).get();
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final courseData = courseSnap.data() ?? const <String, dynamic>{};
      studentName = (userData['fullName'] ?? '').toString();
      studentNo = (userData['studentOrStaffNo'] ?? userData['studentNo'] ?? '')
          .toString();
      courseName = (courseData['courseName'] ?? courseId).toString();
    }

    if (status == AttendanceStatus.absent) {
      absentHours += 1;
    } else if (status == AttendanceStatus.present ||
        status == AttendanceStatus.excused) {
      if (absentHours > 0) {
        absentHours -= 1;
      }
    }

    final ratio =
        totalCourseHours > 0 ? (absentHours / totalCourseHours) : 0.0;
    final absencePercentage =
        double.parse((ratio * 100.0).toStringAsFixed(2));
    final isCriticalRisk = ratio > 0.20;

    final updatedModel = StudentAbsenceRecordModel(
      studentUid: studentUid,
      studentName: studentName,
      studentNo: studentNo,
      courseId: courseId,
      courseName: courseName,
      totalCourseHours: totalCourseHours,
      absentHours: absentHours,
      absencePercentage: absencePercentage,
      isCriticalRisk: isCriticalRisk,
    );

    await recordDocRef.set(updatedModel.toJson());
    return updatedModel;
  }

  @override
  Future<StudentAbsenceRecordModel> evaluateAbsenceRisk(
    String courseId,
    String studentUid,
  ) async {
    final record = await getStudentAbsenceRecord(courseId, studentUid);
    final total = record.totalCourseHours > 0
        ? record.totalCourseHours
        : defaultTotalCourseHours;
    final ratio = record.absentHours / total;
    final percentage = double.parse((ratio * 100.0).toStringAsFixed(2));
    final isCritical = ratio > 0.20;

    if (record.isCriticalRisk != isCritical ||
        record.absencePercentage != percentage) {
      final updated = record.copyWith(
        absencePercentage: percentage,
        isCriticalRisk: isCritical,
      );
      await _recordsRef(courseId).doc(studentUid).set(updated.toJson());
      return updated;
    }
    return record;
  }

  @override
  Stream<List<StudentAbsenceRecordModel>> watchClassAbsenceRecords(
    String courseId,
  ) {
    return _recordsRef(courseId).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => StudentAbsenceRecordModel.fromFirestore(
              doc.data(),
              doc.id,
            ),
          )
          .toList();
    });
  }

  @override
  Future<StudentAbsenceRecordModel> getStudentAbsenceRecord(
    String courseId,
    String studentUid,
  ) async {
    final docRef = _recordsRef(courseId).doc(studentUid);
    final docSnap = await docRef.get();

    if (docSnap.exists && docSnap.data() != null) {
      return StudentAbsenceRecordModel.fromFirestore(
        docSnap.data()!,
        docSnap.id,
      );
    }

    final userSnap = await _usersRef.doc(studentUid).get();
    final courseSnap = await _coursesRef.doc(courseId).get();
    final userData = userSnap.data() ?? const <String, dynamic>{};
    final courseData = courseSnap.data() ?? const <String, dynamic>{};

    final initialModel = StudentAbsenceRecordModel(
      studentUid: studentUid,
      studentName: (userData['fullName'] ?? '').toString(),
      studentNo:
          (userData['studentOrStaffNo'] ?? userData['studentNo'] ?? '')
              .toString(),
      courseId: courseId,
      courseName: (courseData['courseName'] ?? courseId).toString(),
      totalCourseHours: defaultTotalCourseHours,
      absentHours: 0,
      absencePercentage: 0.0,
      isCriticalRisk: false,
    );

    try {
      await docRef.set(initialModel.toJson());
    } catch (_) {
      // Yazma izni yoksa yine de modeli dön
    }

    return initialModel;
  }
}
