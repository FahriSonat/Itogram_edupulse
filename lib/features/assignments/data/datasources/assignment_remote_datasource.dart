import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/submission_status.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';

abstract class AssignmentRemoteDataSource {
  Stream<List<AssignmentModel>> watchAssignments(String courseId);

  Future<void> createAssignment(AssignmentModel assignment);

  Stream<List<SubmissionModel>> watchSubmissions(String assignmentId);

  /// Öğrencinin ödev teslimini `assignments/{id}/submissions/{studentUid}` altına kaydeder.
  /// `SubmissionModel` ile birebir uyumlu olarak `studentUid`, `isLatePenaltyApplied`,
  /// `rawScore`, `finalScore`, `writtenFeedback`, `audioFeedbackUrl` alanlarını yazar.
  Future<void> uploadSubmission(SubmissionModel submission);

  /// Eğitmenin verdiği ham puanı (`rawScore`) kaydeder; eğer `isLatePenaltyApplied == true`
  /// ise otomatik olarak -10 puan geç teslim cezası uygulayarak `finalScore` hesaplar.
  Future<void> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required double rawScore,
    String? writtenFeedback,
    String? audioFeedbackUrl,
  });
}

class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  static const double latePenaltyPoints = 10.0;

  final FirebaseFirestore _firestore;

  AssignmentRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection(FirestorePaths.assignments);

  CollectionReference<Map<String, dynamic>> _submissionsRef(
    String assignmentId,
  ) =>
      _firestore.collection(FirestorePaths.submissions(assignmentId));

  @override
  Stream<List<AssignmentModel>> watchAssignments(String courseId) {
    Query<Map<String, dynamic>> query = _assignmentsRef;
    if (courseId.isNotEmpty) {
      query = query.where('courseId', isEqualTo: courseId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AssignmentModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> createAssignment(AssignmentModel assignment) async {
    final docRef = assignment.assignmentId.isNotEmpty
        ? _assignmentsRef.doc(assignment.assignmentId)
        : _assignmentsRef.doc();

    await docRef.set(assignment.toJson());
  }

  @override
  Stream<List<SubmissionModel>> watchSubmissions(String assignmentId) {
    return _submissionsRef(assignmentId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> uploadSubmission(SubmissionModel submission) async {
    bool isLate = submission.isLatePenaltyApplied;

    // Ödevin son teslim tarihini (dueDate) kontrol ederek geç teslim durumunu doğrula
    try {
      final assignmentSnap =
          await _assignmentsRef.doc(submission.assignmentId).get();
      final dueDateRaw = assignmentSnap.data()?['dueDate'];
      if (dueDateRaw is Timestamp) {
        final dueDate = dueDateRaw.toDate();
        if (submission.submittedAt.isAfter(dueDate)) {
          isLate = true;
        }
      }
    } catch (_) {
      // Ödev dökümanı okunamazsa mevcut isLatePenaltyApplied değerini koru
    }

    final resolvedStatus =
        isLate ? SubmissionStatus.late : SubmissionStatus.submitted;

    final docId = submission.submissionId.isNotEmpty
        ? submission.submissionId
        : submission.studentUid;

    final normalizedSubmission = SubmissionModel(
      submissionId: docId,
      assignmentId: submission.assignmentId,
      studentUid: submission.studentUid,
      studentName: submission.studentName,
      fileUrl: submission.fileUrl,
      fileName: submission.fileName,
      submittedAt: submission.submittedAt,
      status: resolvedStatus,
      isLatePenaltyApplied: isLate,
      rawScore: null,
      finalScore: null,
      writtenFeedback: null,
      audioFeedbackUrl: null,
    );

    await _submissionsRef(submission.assignmentId)
        .doc(docId)
        .set(normalizedSubmission.toJson());
  }

  @override
  Future<void> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required double rawScore,
    String? writtenFeedback,
    String? audioFeedbackUrl,
  }) async {
    final docRef = _submissionsRef(assignmentId).doc(submissionId);
    final existingSnap = await docRef.get();
    final existingData = existingSnap.data();

    final isLatePenaltyApplied =
        existingData?['isLatePenaltyApplied'] as bool? ?? false;

    // Geç teslim cezası (-10 puan) uygulanarak finalScore hesaplanır
    final finalScore = isLatePenaltyApplied
        ? (rawScore - latePenaltyPoints).clamp(0.0, 100.0)
        : rawScore.clamp(0.0, 100.0);

    await docRef.set(
      {
        'rawScore': rawScore,
        'finalScore': finalScore,
        'isLatePenaltyApplied': isLatePenaltyApplied,
        'status': SubmissionStatus.graded.name,
        'writtenFeedback': writtenFeedback?.trim(),
        'audioFeedbackUrl': audioFeedbackUrl,
      },
      SetOptions(merge: true),
    );
  }
}
