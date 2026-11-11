import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../../domain/usecases/create_assignment_usecase.dart';
import '../../domain/usecases/grade_and_feedback_usecase.dart';
import '../../domain/usecases/upload_assignment_submission_usecase.dart';
import 'assignment_state.dart';

class AssignmentCubit extends Cubit<AssignmentState> {
  AssignmentCubit({
    required this._repository,
    required this._createAssignment,
    required this._uploadSubmission,
    required this._gradeAndFeedback,
  }) : super(const AssignmentState()) {
    start();
  }

  final AssignmentRepository _repository;
  final CreateAssignmentUseCase _createAssignment;
  final UploadAssignmentSubmissionUseCase _uploadSubmission;
  final GradeAndFeedbackUseCase _gradeAndFeedback;

  StreamSubscription<List<AssignmentEntity>>? _assignmentSub;
  StreamSubscription<List<SubmissionEntity>>? _submissionSub;

  void start() {
    emit(state.copyWith(status: ViewStatus.loading));
    _assignmentSub?.cancel();
    _submissionSub?.cancel();
    _assignmentSub = _repository.watchAssignments().listen(
      (items) => emit(state.copyWith(status: ViewStatus.loaded, assignments: items)),
      onError: _onError,
    );
    _submissionSub = _repository.watchSubmissions().listen(
      (items) => emit(state.copyWith(submissions: items)),
      onError: _onError,
    );
  }

  void _onError(Object e) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: Failure.from(e).message));

  Future<void> createAssignment({
    required UserEntity actor,
    required String courseName,
    required String title,
    required String description,
    required String rubricCriteria,
    required DateTime dueDate,
  }) => _createAssignment(
    actor: actor,
    courseName: courseName,
    title: title,
    description: description,
    rubricCriteria: rubricCriteria,
    dueDate: dueDate,
  );

  /// Dosyayı yükler; ilerleme [AssignmentState.upload] üzerinden yayınlanır.
  /// Hata mesajını döndürür (başarılıysa null).
  Future<String?> submit({
    required UserEntity actor,
    required AssignmentEntity assignment,
    required PickedFileInfo file,
  }) async {
    if (state.upload?.isUploading ?? false) return 'Devam eden bir yükleme var, lütfen bekleyiniz.';
    emit(
      state.copyWith(
        upload: () => UploadProgress(assignmentId: assignment.id, fileName: file.name, fileSize: file.readableSize),
      ),
    );
    try {
      await _uploadSubmission(
        actor: actor,
        assignment: assignment,
        file: file,
        onProgress: (p) {
          final current = state.upload;
          if (current != null && !isClosed) emit(state.copyWith(upload: () => current.copyWith(progress: p)));
        },
      );
      final current = state.upload;
      if (current != null) emit(state.copyWith(upload: () => current.copyWith(progress: 1, isCompleted: true)));
      return null;
    } catch (e) {
      final message = Failure.from(e).message;
      final current = state.upload;
      if (current != null) emit(state.copyWith(upload: () => current.copyWith(errorMessage: message)));
      return message;
    }
  }

  void dismissUpload() => emit(state.copyWith(upload: () => null));

  Future<void> grade({
    required UserEntity actor,
    required String submissionId,
    required double score,
    String? writtenFeedback,
  }) => _gradeAndFeedback(actor: actor, submissionId: submissionId, score: score, writtenFeedback: writtenFeedback);

  @override
  Future<void> close() {
    _assignmentSub?.cancel();
    _submissionSub?.cancel();
    return super.close();
  }
}
