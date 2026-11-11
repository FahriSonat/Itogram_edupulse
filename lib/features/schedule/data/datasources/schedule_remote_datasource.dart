import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';

/// Firestore `courses` koleksiyonunu canlı dinler.
/// Eğitmen ders saatini, amfi konumunu (`D-107`) veya hoca adını güncellediğinde
/// anlık olarak tüm öğrencilerin ekranında ders kartı ve geri sayım sayacı güncellenir.
abstract class ScheduleRemoteDataSource {
  /// Haftalık ders programını gerçek zamanlı (`snapshots()`) olarak dinler
  Stream<List<Map<String, dynamic>>> watchWeeklySchedule({
    int? dayOfWeek,
    String? instructorId,
    String? studentId,
  });

  /// Yeni bir ders programı kaydı oluşturur
  Future<Map<String, dynamic>> addCourseSchedule({
    required String courseCode,
    required String courseName,
    required String instructorId,
    required String instructorName,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String classroom,
    int credit = 3,
    List<String> enrolledStudentIds = const [],
  });

  /// Mevcut dersin saat (`startTime`, `endTime`), amfi konumunu (`classroom`, örn: `D-107`)
  /// veya hoca adını (`instructorName`) günceller
  Future<Map<String, dynamic>> updateCourseDetails({
    required String courseId,
    String? courseCode,
    String? courseName,
    String? instructorId,
    String? instructorName,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? classroom,
    int? credit,
    List<String>? enrolledStudentIds,
  });

  /// Dersi programdan kaldırır
  Future<void> removeCourseSchedule(String courseId);
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final FirebaseFirestore _firestore;

  ScheduleRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection(FirestorePaths.courses);

  @override
  Stream<List<Map<String, dynamic>>> watchWeeklySchedule({
    int? dayOfWeek,
    String? instructorId,
    String? studentId,
  }) {
    Query<Map<String, dynamic>> query = _coursesRef;

    if (dayOfWeek != null) {
      query = query.where('dayOfWeek', isEqualTo: dayOfWeek);
    }
    if (instructorId != null && instructorId.isNotEmpty) {
      query = query.where('instructorId', isEqualTo: instructorId);
    }
    if (studentId != null && studentId.isNotEmpty) {
      query = query.where('enrolledStudentIds', arrayContains: studentId);
    }

    query = query.orderBy('startTime');

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _normalizeMap(data);
      }).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> addCourseSchedule({
    required String courseCode,
    required String courseName,
    required String instructorId,
    required String instructorName,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String classroom,
    int credit = 3,
    List<String> enrolledStudentIds = const [],
  }) async {
    final docRef = _coursesRef.doc();
    final now = DateTime.now();

    final payload = <String, dynamic>{
      'id': docRef.id,
      'courseCode': courseCode.trim().toUpperCase(),
      'courseName': courseName.trim(),
      'instructorId': instructorId,
      'instructorName': instructorName.trim(),
      'dayOfWeek': dayOfWeek,
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
      'classroom': classroom.trim(),
      'credit': credit,
      'enrolledStudentIds': enrolledStudentIds,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await docRef.set(payload);
    return _normalizeMap(payload);
  }

  @override
  Future<Map<String, dynamic>> updateCourseDetails({
    required String courseId,
    String? courseCode,
    String? courseName,
    String? instructorId,
    String? instructorName,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? classroom,
    int? credit,
    List<String>? enrolledStudentIds,
  }) async {
    final docRef = _coursesRef.doc(courseId);
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (courseCode != null) {
      updates['courseCode'] = courseCode.trim().toUpperCase();
    }
    if (courseName != null) updates['courseName'] = courseName.trim();
    if (instructorId != null) updates['instructorId'] = instructorId;
    if (instructorName != null) {
      updates['instructorName'] = instructorName.trim();
    }
    if (dayOfWeek != null) updates['dayOfWeek'] = dayOfWeek;
    if (startTime != null) updates['startTime'] = startTime.trim();
    if (endTime != null) updates['endTime'] = endTime.trim();
    if (classroom != null) updates['classroom'] = classroom.trim();
    if (credit != null) updates['credit'] = credit;
    if (enrolledStudentIds != null) {
      updates['enrolledStudentIds'] = enrolledStudentIds;
    }

    await docRef.set(updates, SetOptions(merge: true));
    final updatedSnap = await docRef.get();
    final data = Map<String, dynamic>.from(updatedSnap.data() ?? updates);
    data['id'] = docRef.id;
    return _normalizeMap(data);
  }

  @override
  Future<void> removeCourseSchedule(String courseId) async {
    await _coursesRef.doc(courseId).delete();
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
