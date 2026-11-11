import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/course_schedule_model.dart';

abstract class ScheduleRemoteDataSource {
  Stream<List<CourseScheduleModel>> watchCourses();
  Future<List<CourseScheduleModel>> getCourses();
  Future<void> upsertCourse(CourseScheduleModel course);
  Future<void> deleteCourse(String id);
  String newId();
}

class LocalScheduleRemoteDataSource implements ScheduleRemoteDataSource {
  LocalScheduleRemoteDataSource(this._storage);

  final LocalStorageService _storage;

  static List<CourseScheduleModel> _sorted(List<Map<String, dynamic>> docs) {
    final list = docs.map(CourseScheduleModel.fromJson).toList();
    list.sort((a, b) {
      final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
      return byDay != 0 ? byDay : a.startMinutes.compareTo(b.startMinutes);
    });
    return list;
  }

  @override
  Stream<List<CourseScheduleModel>> watchCourses() => _storage.watch(FirestorePaths.courses).map(_sorted);

  @override
  Future<List<CourseScheduleModel>> getCourses() async => _sorted(_storage.getAll(FirestorePaths.courses));

  @override
  Future<void> upsertCourse(CourseScheduleModel course) => _storage.upsert(FirestorePaths.courses, course.toJson());

  @override
  Future<void> deleteCourse(String id) => _storage.delete(FirestorePaths.courses, id);

  @override
  String newId() => _storage.generateId('c');
}
