import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/letter_grade.dart';
import '../../../../core/enums/user_role.dart';

/// Firestore `courses/{courseId}/grades/{studentUid}` dökümanlarını yönetir.
/// Eğitmen için sisteme kayıtlı öğrencilerin listesini getirir ve seçilen öğrencinin
/// notunu kaydeder, günceller veya siler.
abstract class GradesRemoteDataSource {
  /// Eğitmen için sisteme kayıtlı öğrencilerin listesini getirir
  Future<List<Map<String, dynamic>>> getRegisteredStudents({String? courseId});

  /// Bir derse ait tüm öğrenci notlarını gerçek zamanlı dinler (Eğitmen görünümü)
  Stream<List<Map<String, dynamic>>> watchCourseGrades(String courseId);

  /// Öğrencinin tüm derslerdeki notlarını gerçek zamanlı dinler (Öğrenci görünümü)
  Stream<List<Map<String, dynamic>>> watchStudentGrades(String studentId);

  /// Seçilen öğrencinin `courses/{courseId}/grades/{studentUid}` not dökümanını kaydeder veya günceller
  Future<Map<String, dynamic>> upsertStudentGrade({
    required String courseId,
    required String courseCode,
    required String courseName,
    required int credit,
    required String studentId,
    required String studentName,
    required String studentNo,
    double? midtermScore,
    double? finalScore,
    double? projectScore,
    double midtermWeight = 0.4,
    double finalWeight = 0.6,
    double projectWeight = 0.0,
    LetterGrade? letterGrade,
  });

  /// Seçilen öğrencinin `courses/{courseId}/grades/{studentUid}` not dökümanını siler
  Future<void> deleteStudentGrade({
    required String courseId,
    required String studentId,
  });
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
  Future<List<Map<String, dynamic>>> getRegisteredStudents({
    String? courseId,
  }) async {
    final snapshot = await _usersRef
        .where('role', isEqualTo: UserRole.student.name)
        .get();

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return _normalizeMap(data);
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCourseGrades(String courseId) {
    return _courseGradesRef(courseId)
        .orderBy('studentNo')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _normalizeMap(data);
      }).toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchStudentGrades(String studentId) {
    return _firestore
        .collectionGroup('grades')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _normalizeMap(data);
      }).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> upsertStudentGrade({
    required String courseId,
    required String courseCode,
    required String courseName,
    required int credit,
    required String studentId,
    required String studentName,
    required String studentNo,
    double? midtermScore,
    double? finalScore,
    double? projectScore,
    double midtermWeight = 0.4,
    double finalWeight = 0.6,
    double projectWeight = 0.0,
    LetterGrade? letterGrade,
  }) async {
    final docRef = _courseGradesRef(courseId).doc(studentId);
    final now = DateTime.now();

    final average = _calculateWeightedAverage(
      midterm: midtermScore,
      finalExam: finalScore,
      project: projectScore,
      midtermWeight: midtermWeight,
      finalWeight: finalWeight,
      projectWeight: projectWeight,
    );

    final resolvedLetter = letterGrade ?? _resolveLetterGrade(average);

    final payload = <String, dynamic>{
      'id': studentId,
      'courseId': courseId,
      'courseCode': courseCode,
      'courseName': courseName,
      'credit': credit,
      'studentId': studentId,
      'studentName': studentName,
      'studentNo': studentNo,
      'midtermScore': midtermScore,
      'finalScore': finalScore,
      'projectScore': projectScore,
      'midtermWeight': midtermWeight,
      'finalWeight': finalWeight,
      'projectWeight': projectWeight,
      'averageScore': average,
      'letterGrade': resolvedLetter.name,
      'updatedAt': Timestamp.fromDate(now),
    };

    await docRef.set(payload, SetOptions(merge: true));
    return _normalizeMap(payload);
  }

  @override
  Future<void> deleteStudentGrade({
    required String courseId,
    required String studentId,
  }) async {
    await _courseGradesRef(courseId).doc(studentId).delete();
  }

  double? _calculateWeightedAverage({
    double? midterm,
    double? finalExam,
    double? project,
    required double midtermWeight,
    required double finalWeight,
    required double projectWeight,
  }) {
    if (midterm == null && finalExam == null && project == null) {
      return null;
    }
    final m = (midterm ?? 0.0) * midtermWeight;
    final f = (finalExam ?? 0.0) * finalWeight;
    final p = (project ?? 0.0) * projectWeight;
    return double.parse((m + f + p).toStringAsFixed(2));
  }

  LetterGrade _resolveLetterGrade(double? average) {
    if (average == null) return LetterGrade.NA;
    if (average >= 90) return LetterGrade.AA;
    if (average >= 85) return LetterGrade.BA;
    if (average >= 80) return LetterGrade.BB;
    if (average >= 75) return LetterGrade.CB;
    if (average >= 70) return LetterGrade.CC;
    if (average >= 65) return LetterGrade.DC;
    if (average >= 60) return LetterGrade.DD;
    if (average >= 50) return LetterGrade.FD;
    return LetterGrade.FF;
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
