import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/announcement_model.dart';

abstract class AnnouncementRemoteDataSource {
  Stream<List<AnnouncementModel>> watchAnnouncements();
  Future<void> saveAnnouncement(AnnouncementModel announcement);
  Future<void> deleteAnnouncement(String id);
  String newId();
}

class LocalAnnouncementRemoteDataSource implements AnnouncementRemoteDataSource {
  LocalAnnouncementRemoteDataSource(this._storage);

  final LocalStorageService _storage;

  @override
  Stream<List<AnnouncementModel>> watchAnnouncements() =>
      _storage.watch(FirestorePaths.announcements).map((docs) => docs.map(AnnouncementModel.fromJson).toList());

  @override
  Future<void> saveAnnouncement(AnnouncementModel announcement) =>
      _storage.upsert(FirestorePaths.announcements, announcement.toJson());

  @override
  Future<void> deleteAnnouncement(String id) => _storage.delete(FirestorePaths.announcements, id);

  @override
  String newId() => _storage.generateId('a');
}
