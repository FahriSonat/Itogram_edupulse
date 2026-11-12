import 'dart:async';

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
    late final StreamController<List<CourseGradeModel>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? coursesSub;
    final courseGradeSubs =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final gradesByCourse = <String, List<CourseGradeModel>>{};

    void emitCombined() {
      if (controller.isClosed) return;
      final combined = gradesByCourse.values.expand((list) => list).toList();
      controller.add(combined);
    }

    controller = StreamController<List<CourseGradeModel>>(
      onListen: () {
        coursesSub = _firestore
            .collection(FirestorePaths.courses)
            .snapshots()
            .listen(
          (coursesSnap) {
            final activeCourseIds =
                coursesSnap.docs.map((doc) => doc.id).toSet();

            final removedIds = courseGradeSubs.keys
                .where((id) => !activeCourseIds.contains(id))
                .toList();
            for (final id in removedIds) {
              courseGradeSubs.remove(id)?.cancel();
              gradesByCourse.remove(id);
            }

            if (activeCourseIds.isEmpty) {
              emitCombined();
              return;
            }

            for (final courseId in activeCourseIds) {
              if (courseGradeSubs.containsKey(courseId)) continue;
              gradesByCourse[courseId] = const <CourseGradeModel>[];
              courseGradeSubs[courseId] = _courseGradesRef(courseId)
                  .where('studentUid', isEqualTo: studentUid)
                  .snapshots()
                  .listen(
                (gradeSnap) {
                  gradesByCourse[courseId] = gradeSnap.docs
                      .map((doc) =>
                          CourseGradeModel.fromFirestore(doc.data(), doc.id))
                      .toList();
                  emitCombined();
                },
                onError: (Object error, StackTrace stack) {
                  if (!controller.isClosed) {
                    controller.addError(error, stack);
                  }
                },
              );
            }
            emitCombined();
          },
          onError: (Object error, StackTrace stack) {
            if (!controller.isClosed) {
              controller.addError(error, stack);
            }
          },
        );
      },
      onCancel: () async {
        await coursesSub?.cancel();
        for (final sub in courseGradeSubs.values) {
          await sub.cancel();
        }
        courseGradeSubs.clear();
      },
    );

    return controller.stream;
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
