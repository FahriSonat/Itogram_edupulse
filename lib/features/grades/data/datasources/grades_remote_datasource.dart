import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/user_role.dart';
import '../models/course_grade_model.dart';

/// Firestore `courses/{courseId}/grades/{studentUid}` dökümanlarını yönetir.
/// Eğitmen için sisteme kayıtlı öğrencilerin listesini getirir ve seçilen öğrencinin
/// notunu kaydeder, günceller veya siler.
abstract class GradesRemoteDataSource {
  Stream<List<CourseGradeModel>> watchStudentGrades(String studentUid);

  Stream<List<CourseGradeModel>> watchCourseGrades(String courseId);

  Future<void> manageStudentGrade(CourseGradeModel grade);

  Future<void> deleteStudentGrade(String gradeId, String courseId);

  Future<List<Map<String, dynamic>>> getRegisteredStudents();
}

class GradesRemoteDataSourceImpl implements GradesRemoteDataSource {
  final FirebaseFirestore _firestore;

  GradesRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _courseGradesRef(String courseId) =>
      _firestore.collection(FirestorePaths.grades(courseId));

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(FirestorePaths.users);

  @override
  Stream<List<CourseGradeModel>> watchStudentGrades(String studentUid) {
    return _firestore
        .collectionGroup('grades')
        .where('studentUid', isEqualTo: studentUid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CourseGradeModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Stream<List<CourseGradeModel>> watchCourseGrades(String courseId) {
    return _courseGradesRef(courseId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CourseGradeModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> manageStudentGrade(CourseGradeModel grade) async {
    final docId =
        grade.gradeId.isNotEmpty ? grade.gradeId : grade.studentUid;
    await _courseGradesRef(grade.courseId).doc(docId).set(grade.toJson());
  }

  @override
  Future<void> deleteStudentGrade(String gradeId, String courseId) async {
    await _courseGradesRef(courseId).doc(gradeId).delete();
  }

  @override
  Future<List<Map<String, dynamic>>> getRegisteredStudents() async {
    final snapshot = await _usersRef
        .where('role', isEqualTo: UserRole.student.name)
        .get();

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['uid'] = doc.id;
      return data;
    }).toList();
  }
}
