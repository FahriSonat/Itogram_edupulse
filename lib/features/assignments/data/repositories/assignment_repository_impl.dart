import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../datasources/assignment_remote_datasource.dart';
import '../datasources/assignment_storage_datasource.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  AssignmentRepositoryImpl({required this.remote, required this.storage, required this.notifications});

  final AssignmentRemoteDataSource remote;
  final AssignmentStorageDataSource storage;
  final NotificationService notifications;

  @override
  Stream<List<AssignmentEntity>> watchAssignments() => remote.watchAssignments();

  @override
  Stream<List<SubmissionEntity>> watchSubmissions() => remote.watchSubmissions();

  @override
  Future<AssignmentEntity> createAssignment({
    required String courseName,
    required String title,
    required String description,
    required String rubricCriteria,
    required DateTime dueDate,
    required UserEntity author,
  }) async {
    try {
      final model = AssignmentModel(
        id: remote.newId('as'),
        courseName: courseName,
        title: title,
        description: description,
        rubricCriteria: rubricCriteria,
        dueDate: dueDate,
        createdByUid: author.uid,
        createdByName: author.fullName,
        createdAt: DateTime.now(),
      );
      await remote.saveAssignment(model);
      await notifications.send(
        title: 'Yeni ödev: $title',
        body: '$courseName dersine yeni bir ödev eklendi.',
        kind: NotificationKind.assignment,
        targetRole: UserRole.student,
      );
      return model;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<SubmissionEntity> uploadSubmission({
    required AssignmentEntity assignment,
    required UserEntity student,
    required PickedFileInfo file,
    required bool isLate,
    required void Function(double progress) onProgress,
  }) async {
    try {
      await storage.uploadFile(
        file: file,
        storagePath: 'submissions/${assignment.id}/${student.uid}',
        onProgress: onProgress,
      );
      final existing = remote.findSubmission(assignmentId: assignment.id, studentUid: student.uid);
      final model = SubmissionModel(
        id: existing?.id ?? remote.newId('sub'),
        assignmentId: assignment.id,
        studentUid: student.uid,
        studentName: student.fullName,
        studentNo: student.schoolNo,
        fileName: file.name,
        fileSizeBytes: file.sizeBytes,
        submittedAt: DateTime.now(),
        isLate: isLate,
      );
      await remote.saveSubmission(model);
      return model;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  SubmissionEntity? findSubmission({required String assignmentId, required String studentUid}) =>
      remote.findSubmission(assignmentId: assignmentId, studentUid: studentUid);

  @override
  Future<SubmissionEntity> gradeSubmission({
    required String submissionId,
    required double score,
    String? writtenFeedback,
  }) async {
    try {
      final existing = remote.getSubmission(submissionId);
      if (existing == null) throw const NotFoundFailure('Teslim kaydı bulunamadı.');
      final updated = SubmissionModel.fromEntity(
        existing.copyWith(score: score, writtenFeedback: writtenFeedback ?? '', gradedAt: DateTime.now()),
      );
      await remote.saveSubmission(updated);
      final penaltyNote = updated.isLate ? ' (geç teslim cezası sonrası)' : '';
      await notifications.send(
        title: 'Ödevin değerlendirildi',
        body: '${updated.fileName} için puanın: ${updated.finalScore!.toStringAsFixed(0)}$penaltyNote',
        kind: NotificationKind.grade,
        targetUid: updated.studentUid,
      );
      return updated;
    } catch (e) {
      throw Failure.from(e);
    }
  }
}
