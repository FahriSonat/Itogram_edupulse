import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/attendance_session_model.dart';
import '../models/student_absence_record_model.dart';

abstract class AttendanceRemoteDataSource {
  Stream<List<AttendanceSessionModel>> watchSessions();
  List<AttendanceSessionModel> getSessions();
  AttendanceSessionModel? getSession(String id);
  Future<void> saveSession(AttendanceSessionModel session);

  Stream<List<StudentAbsenceRecordModel>> watchAbsenceRecords();
  List<StudentAbsenceRecordModel> getAbsenceRecords();
  Future<void> saveAbsenceRecords(List<StudentAbsenceRecordModel> records);

  String newId();
}

class LocalAttendanceRemoteDataSource implements AttendanceRemoteDataSource {
  LocalAttendanceRemoteDataSource(this._storage);

  final LocalStorageService _storage;

  static List<AttendanceSessionModel> _sessions(List<Map<String, dynamic>> docs) {
    final list = docs.map(AttendanceSessionModel.fromJson).toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  @override
  Stream<List<AttendanceSessionModel>> watchSessions() =>
      _storage.watch(FirestorePaths.attendanceSessions).map(_sessions);

  @override
  List<AttendanceSessionModel> getSessions() => _sessions(_storage.getAll(FirestorePaths.attendanceSessions));

  @override
  AttendanceSessionModel? getSession(String id) {
    final doc = _storage.getById(FirestorePaths.attendanceSessions, id);
    return doc == null ? null : AttendanceSessionModel.fromJson(doc);
  }

  @override
  Future<void> saveSession(AttendanceSessionModel session) =>
      _storage.upsert(FirestorePaths.attendanceSessions, session.toJson());

  @override
  Stream<List<StudentAbsenceRecordModel>> watchAbsenceRecords() => _storage
      .watch(FirestorePaths.absenceRecords)
      .map((docs) => docs.map(StudentAbsenceRecordModel.fromJson).toList());

  @override
  List<StudentAbsenceRecordModel> getAbsenceRecords() =>
      _storage.getAll(FirestorePaths.absenceRecords).map(StudentAbsenceRecordModel.fromJson).toList();

  @override
  Future<void> saveAbsenceRecords(List<StudentAbsenceRecordModel> records) =>
      _storage.upsertAll(FirestorePaths.absenceRecords, records.map((r) => r.toJson()).toList());

  @override
  String newId() => _storage.generateId('att');
}
