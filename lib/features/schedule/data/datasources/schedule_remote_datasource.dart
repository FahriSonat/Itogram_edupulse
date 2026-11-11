import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../models/course_schedule_model.dart';

/// Firestore `courses` koleksiyonunu canlı dinler.
/// Eğitmen ders saatini (`startTime`, `endTime`), amfi konumunu (`roomLocation`, örn: `D-107`)
/// veya hoca adını (`instructorName`) güncellediğinde anlık olarak tüm öğrencilerin
/// ekranında ders kartı ve geri sayım sayacı güncellenir.
abstract class ScheduleRemoteDataSource {
  Stream<List<CourseScheduleModel>> watchWeeklySchedule();

  Future<void> addCourse(CourseScheduleModel course);

  Future<void> updateCourse(CourseScheduleModel course);

  Future<void> removeCourse(String courseId);
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final FirebaseFirestore _firestore;

  ScheduleRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection(FirestorePaths.courses);

  @override
  Stream<List<CourseScheduleModel>> watchWeeklySchedule() {
    return _coursesRef.orderBy('startTime').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CourseScheduleModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> addCourse(CourseScheduleModel course) async {
    final docRef = course.courseId.isNotEmpty
        ? _coursesRef.doc(course.courseId)
        : _coursesRef.doc();

    await docRef.set(course.toJson());
  }

  @override
  Future<void> updateCourse(CourseScheduleModel course) async {
    await _coursesRef.doc(course.courseId).set(
          course.toJson(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> removeCourse(String courseId) async {
    await _coursesRef.doc(courseId).delete();
  }
}
