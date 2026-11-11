import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/view_status.dart';
import '../../../../core/services/audio_recorder_service.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../../schedule/domain/usecases/watch_weekly_schedule_usecase.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/usecases/create_assignment_usecase.dart';
import '../../domain/usecases/grade_and_feedback_usecase.dart';
import '../../domain/usecases/upload_assignment_submission_usecase.dart';
import 'assignment_state.dart';

/// Aktif ödevleri, Storage dosya yükleme durumunu, gecikme bayraklarını ve
/// eğitmenin rubrik puanlama / sesli kayıt süreçlerini yönetir.
class AssignmentCubit extends Cubit<AssignmentState> {
  AssignmentCubit({
    required this.watchWeeklyScheduleUseCase,
    required this.createAssignmentUseCase,
    required this.uploadAssignmentSubmissionUseCase,
    required this.gradeAndFeedbackUseCase,
    this.audioRecorderService,
  }) : super(const AssignmentState());

  final WatchWeeklyScheduleUseCase watchWeeklyScheduleUseCase;
  final CreateAssignmentUseCase createAssignmentUseCase;
  final UploadAssignmentSubmissionUseCase uploadAssignmentSubmissionUseCase;
  final GradeAndFeedbackUseCase gradeAndFeedbackUseCase;

  /// Testlerde null bırakılabilir (mikrofon gerektirir).
  final AudioRecorderService? audioRecorderService;

  StreamSubscription<dynamic>? _scheduleSub;
  StreamSubscription<dynamic>? _assignmentsSub;
  StreamSubscription<dynamic>? _submissionsSub;

  /// Ders listesini yükler; ilk dersi otomatik seçer.
  void start() {
    emit(state.copyWith(status: ViewStatus.loading));
    _scheduleSub?.cancel();
    _scheduleSub = watchWeeklyScheduleUseCase().listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (all) {
          final seen = <String>{};
          final courses = <CourseScheduleEntity>[for (final c in all) if (seen.add(c.courseId)) c];
          emit(state.copyWith(courses: courses, status: courses.isEmpty ? ViewStatus.loaded : null));
          final selected = state.selectedCourseId;
          if (courses.isNotEmpty && (selected == null || courses.every((c) => c.courseId != selected))) {
            selectCourse(courses.first.courseId);
          }
        },
      );
    });
  }

  void selectCourse(String courseId) {
    emit(state.copyWith(selectedCourseId: courseId, status: ViewStatus.loading));
    _assignmentsSub?.cancel();
    _assignmentsSub = createAssignmentUseCase.watch(courseId).listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (list) => emit(state.copyWith(
          status: ViewStatus.loaded,
          assignments: List<AssignmentEntity>.of(list)..sort((a, b) => a.dueDate.compareTo(b.dueDate)),
        )),
      );
    });
  }

  /// Bir ödevin teslimlerini izlemeye başlar.
  void openAssignment(String assignmentId) {
    if (state.openAssignmentId == assignmentId && _submissionsSub != null) return;
    emit(state.copyWith(openAssignmentId: assignmentId, submissions: const [], submissionsStatus: ViewStatus.loading));
    _submissionsSub?.cancel();
    _submissionsSub = gradeAndFeedbackUseCase.watchSubmissions(assignmentId).listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(submissionsStatus: ViewStatus.failure, errorMessage: failure.message)),
        (list) => emit(state.copyWith(submissionsStatus: ViewStatus.loaded, submissions: list)),
      );
    });
  }

  Future<bool> createAssignment({
    required String courseId,
    required String courseName,
    required String title,
    required String description,
    required String rubricCriteria,
    required DateTime dueDate,
  }) async {
    final result = await createAssignmentUseCase(AssignmentEntity(
      assignmentId: '',
      courseId: courseId,
      courseName: courseName,
      title: title,
      description: description,
      rubricCriteria: rubricCriteria,
      dueDate: dueDate,
    ));
    return result.fold(
      (failure) {
        emit(state.copyWith(actionMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(actionMessage: 'Ödev yayınlandı.'));
        return true;
      },
    );
  }

  /// Kural 2: süre geçtiyse yükleme ENGELLENMEZ, -10 ceza bayrağı çakılır.
  Future<void> uploadSubmission({
    required AssignmentEntity assignment,
    required String studentUid,
    required String studentName,
    required String localFilePath,
    required String fileName,
  }) async {
    final isLate = DateTime.now().isAfter(assignment.dueDate);
    UploadProgress progress(double value, {bool done = false, String? error}) => UploadProgress(
          assignmentId: assignment.assignmentId,
          fileName: fileName,
          progress: value,
          isUploading: !done && error == null,
          isCompleted: done,
          isLate: isLate,
          errorMessage: error,
        );

    emit(state.copyWith(upload: progress(0)));
    String? error;
    await for (final event in uploadAssignmentSubmissionUseCase.withProgress(
      assignment: assignment,
      studentUid: studentUid,
      studentName: studentName,
      localFilePath: localFilePath,
      fileName: fileName,
    )) {
      if (isClosed) return;
      event.fold(
        (failure) => error = failure.message,
        (value) => emit(state.copyWith(upload: progress(value))),
      );
      if (error != null) break;
    }
    if (isClosed) return;
    if (error != null) {
      emit(state.copyWith(upload: progress(state.upload?.progress ?? 0, error: error)));
      return;
    }
    emit(state.copyWith(
      upload: progress(1, done: true),
      actionMessage: isLate ? 'Ödev teslim edildi — GECİKMİŞ TESLİM (-10 Ceza Puanı) uygulandı.' : 'Ödev teslim edildi.',
    ));
  }

  void clearUpload() => emit(state.copyWith(clearUpload: true));

  // ------------------------------------------------ Sesli geribildirim (eğitmen)

  Future<void> startRecording() async {
    final recorder = audioRecorderService;
    if (recorder == null) return;
    final path = await recorder.startRecording();
    if (path == null) {
      emit(state.copyWith(actionMessage: 'Mikrofon izni verilmedi.'));
      return;
    }
    emit(state.copyWith(isRecording: true, clearRecording: true));
  }

  Future<void> stopRecording() async {
    final path = await audioRecorderService?.stopRecording();
    emit(state.copyWith(isRecording: false, recordedAudioPath: path));
  }

  Future<void> discardRecording() async {
    await audioRecorderService?.cancelRecording();
    emit(state.copyWith(isRecording: false, clearRecording: true));
  }

  Future<bool> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required double rawScore,
    String? writtenFeedback,
  }) async {
    emit(state.copyWith(isGrading: true));
    final result = await gradeAndFeedbackUseCase(
      assignmentId: assignmentId,
      submissionId: submissionId,
      rawScore: rawScore,
      writtenFeedback: writtenFeedback,
      localAudioPath: state.recordedAudioPath,
    );
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(isGrading: false, actionMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(isGrading: false, clearRecording: true, actionMessage: 'Puan kaydedildi.'));
        return true;
      },
    );
  }

  @override
  Future<void> close() {
    _scheduleSub?.cancel();
    _assignmentsSub?.cancel();
    _submissionsSub?.cancel();
    return super.close();
  }
}
