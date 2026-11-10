import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/submission_status.dart';

abstract class AssignmentRemoteDataSource {
  Stream<List<Map<String, dynamic>>> watchAssignments({String? courseId});

  Future<Map<String, dynamic>> createAssignment({
    required String courseId,
    required String courseName,
    required String title,
    required String description,
    required DateTime dueDate,
    required String instructorId,
    bool allowLateSubmission = true,
    int maxScore = 100,
  });

  Stream<List<Map<String, dynamic>>> watchSubmissions(String assignmentId);

  Future<Map<String, dynamic>?> getStudentSubmission({
    required String assignmentId,
    required String studentId,
  });

  Future<Map<String, dynamic>> saveSubmission({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String studentNo,
    required String fileUrl,
    required String fileName,
    required DateTime dueDate,
    String? studentNote,
  });

  Future<Map<String, dynamic>> gradeAndProvideFeedback({
    required String assignmentId,
    required String submissionId,
    required double score,
    String? writtenFeedback,
    String? audioFeedbackUrl,
  });
}

class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  final FirebaseFirestore _firestore;

  AssignmentRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection(FirestorePaths.assignments);

  CollectionReference<Map<String, dynamic>> _submissionsRef(
          String assignmentId) =>
      _firestore.collection(FirestorePaths.submissions(assignmentId));

  @override
  Stream<List<Map<String, dynamic>>> watchAssignments({String? courseId}) {
    Query<Map<String, dynamic>> query = _assignmentsRef;
    if (courseId != null && courseId.isNotEmpty) {
      query = query.where('courseId', isEqualTo: courseId);
    }
    query = query.orderBy('dueDate', descending: false);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _normalizeMap(data);
      }).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> createAssignment({
    required String courseId,
    required String courseName,
    required String title,
    required String description,
    required DateTime dueDate,
    required String instructorId,
    bool allowLateSubmission = true,
    int maxScore = 100,
  }) async {
    final docRef = _assignmentsRef.doc();
    final now = DateTime.now();

    final payload = <String, dynamic>{
      'id': docRef.id,
      'courseId': courseId,
      'courseName': courseName,
      'title': title.trim(),
      'description': description.trim(),
      'dueDate': Timestamp.fromDate(dueDate),
      'instructorId': instructorId,
      'allowLateSubmission': allowLateSubmission,
      'maxScore': maxScore,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await docRef.set(payload);
    return _normalizeMap(payload);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchSubmissions(String assignmentId) {
    return _submissionsRef(assignmentId)
        .orderBy('submittedAt', descending: true)
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
  Future<Map<String, dynamic>?> getStudentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    final doc = await _submissionsRef(assignmentId).doc(studentId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return _normalizeMap(data);
  }

  @override
  Future<Map<String, dynamic>> saveSubmission({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String studentNo,
    required String fileUrl,
    required String fileName,
    required DateTime dueDate,
    String? studentNote,
  }) async {
    final now = DateTime.now();
    final isLate = now.isAfter(dueDate);
    final status =
        isLate ? SubmissionStatus.late : SubmissionStatus.submitted;

    final docRef = _submissionsRef(assignmentId).doc(studentId);
    final payload = <String, dynamic>{
      'id': studentId,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'studentNo': studentNo,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'studentNote': studentNote,
      'status': status.name,
      'isLate': isLate,
      'submittedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await docRef.set(payload, SetOptions(merge: true));
    return _normalizeMap(payload);
  }

  @override
  Future<Map<String, dynamic>> gradeAndProvideFeedback({
    required String assignmentId,
    required String submissionId,
    required double score,
    String? writtenFeedback,
    String? audioFeedbackUrl,
  }) async {
    final now = DateTime.now();
    final docRef = _submissionsRef(assignmentId).doc(submissionId);

    final updates = <String, dynamic>{
      'score': score,
      'status': SubmissionStatus.graded.name,
      'instructorFeedback': writtenFeedback?.trim(),
      'audioFeedbackUrl': audioFeedbackUrl,
      'gradedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await docRef.set(updates, SetOptions(merge: true));
    final updatedDoc = await docRef.get();
    final data = Map<String, dynamic>.from(updatedDoc.data() ?? updates);
    data['id'] = docRef.id;
    return _normalizeMap(data);
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

