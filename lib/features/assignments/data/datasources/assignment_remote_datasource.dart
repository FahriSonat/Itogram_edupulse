import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';

abstract class AssignmentRemoteDataSource {
  Stream<List<AssignmentModel>> watchAssignments();
  Stream<List<SubmissionModel>> watchSubmissions();
  Future<void> saveAssignment(AssignmentModel assignment);
  Future<void> saveSubmission(SubmissionModel submission);
  SubmissionModel? findSubmission({required String assignmentId, required String studentUid});
  SubmissionModel? getSubmission(String id);
  String newId(String prefix);
}

class LocalAssignmentRemoteDataSource implements AssignmentRemoteDataSource {
  LocalAssignmentRemoteDataSource(this._storage);

  final LocalStorageService _storage;

  @override
  Stream<List<AssignmentModel>> watchAssignments() => _storage.watch(FirestorePaths.assignments).map((docs) {
    final list = docs.map(AssignmentModel.fromJson).toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  });

  @override
  Stream<List<SubmissionModel>> watchSubmissions() => _storage.watch(FirestorePaths.submissions).map((docs) {
    final list = docs.map(SubmissionModel.fromJson).toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  });

  @override
  Future<void> saveAssignment(AssignmentModel assignment) =>
      _storage.upsert(FirestorePaths.assignments, assignment.toJson());

  @override
  Future<void> saveSubmission(SubmissionModel submission) =>
      _storage.upsert(FirestorePaths.submissions, submission.toJson());

  @override
  SubmissionModel? findSubmission({required String assignmentId, required String studentUid}) {
    for (final doc in _storage.getAll(FirestorePaths.submissions)) {
      if (doc['assignmentId'] == assignmentId && doc['studentUid'] == studentUid) {
        return SubmissionModel.fromJson(doc);
      }
    }
    return null;
  }

  @override
  SubmissionModel? getSubmission(String id) {
    final doc = _storage.getById(FirestorePaths.submissions, id);
    return doc == null ? null : SubmissionModel.fromJson(doc);
  }

  @override
  String newId(String prefix) => _storage.generateId(prefix);
}
