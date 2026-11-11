// Geliştirici 5 (Ahmet) — AnnouncementCubit ve duyuru UseCase'leri testleri.
// Canlı duyuru akışı, takvim günü / kategori filtreleri ve Anlık Kriz Yayını.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/announcement_type.dart';
import 'package:itogram_edupulse/features/announcements/domain/entities/announcement_entity.dart';
import 'package:itogram_edupulse/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:itogram_edupulse/features/announcements/domain/usecases/create_announcement_usecase.dart';
import 'package:itogram_edupulse/features/announcements/domain/usecases/send_instant_crisis_push_usecase.dart';
import 'package:itogram_edupulse/features/announcements/domain/usecases/watch_announcements_usecase.dart';
import 'package:itogram_edupulse/features/announcements/presentation/cubit/announcement_cubit.dart';
import 'package:itogram_edupulse/features/announcements/presentation/cubit/announcement_state.dart';

class _FakeAnnouncementRepository implements AnnouncementRepository {
  final StreamController<List<AnnouncementEntity>> controller = StreamController<List<AnnouncementEntity>>.broadcast();
  final List<AnnouncementEntity> created = <AnnouncementEntity>[];
  final List<Map<String, String?>> pushes = <Map<String, String?>>[];
  Object? error;

  @override
  Stream<List<AnnouncementEntity>> watchAnnouncements() => controller.stream;

  @override
  Future<void> createAnnouncement(AnnouncementEntity announcement) async {
    final e = error;
    if (e != null) throw e;
    created.add(announcement);
  }

  @override
  Future<void> sendInstantCrisisPush({required String title, required String body, String? targetCourseId}) async {
    final e = error;
    if (e != null) throw e;
    pushes.add(<String, String?>{'title': title, 'body': body, 'target': targetCourseId});
  }
}

AnnouncementEntity _a(String id, AnnouncementType type, DateTime? date) => AnnouncementEntity(
      id: id,
      title: 'Duyuru $id',
      content: 'İçerik',
      type: type,
      eventDate: date,
      authorName: 'Fahri Hoca',
    );

void main() {
  final DateTime nov13 = DateTime(2026, 11, 13, 14);
  final DateTime nov20 = DateTime(2026, 11, 20, 9);

  final List<AnnouncementEntity> seed = <AnnouncementEntity>[
    _a('1', AnnouncementType.exam, nov13),
    _a('2', AnnouncementType.event, nov13.add(const Duration(hours: 3))), // aynı gün, farklı saat
    _a('3', AnnouncementType.event, nov20),
    _a('4', AnnouncementType.general, null), // tarihsiz duyuru
  ];

  late _FakeAnnouncementRepository repository;
  late AnnouncementCubit cubit;
  late List<AnnouncementState> emitted;

  setUp(() {
    repository = _FakeAnnouncementRepository();
    cubit = AnnouncementCubit(
      watchAnnouncementsUseCase: WatchAnnouncementsUseCase(repository),
      createAnnouncementUseCase: CreateAnnouncementUseCase(repository),
      sendInstantCrisisPushUseCase: SendInstantCrisisPushUseCase(repository),
    );
    emitted = <AnnouncementState>[];
    cubit.stream.listen(emitted.add);
  });

  tearDown(() async {
    await cubit.close();
    await repository.controller.close();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  Future<AnnouncementLoaded> loadSeed() async {
    cubit.startWatchingAnnouncements();
    repository.controller.add(seed);
    await flush();
    return cubit.state as AnnouncementLoaded;
  }

  List<String> ids(AnnouncementState s) => (s as AnnouncementLoaded).filteredAnnouncements.map((e) => e.id).toList();

  test('başlangıç durumu AnnouncementInitial', () {
    expect(cubit.state, const AnnouncementInitial());
  });

  group('canlı izleme (snapshots)', () {
    test('AnnouncementLoading → AnnouncementLoaded, filtre yokken tüm liste', () async {
      final loaded = await loadSeed();

      expect(emitted.first, const AnnouncementLoading());
      expect(loaded.allAnnouncements, seed);
      expect(loaded.filteredAnnouncements, seed);
      expect(loaded.selectedDate, isNull);
      expect(loaded.selectedType, isNull);
    });

    test('Firestore\'dan yeni veri gelince liste anında güncellenir', () async {
      await loadSeed();
      repository.controller.add(<AnnouncementEntity>[seed.first]);
      await flush();
      expect(ids(cubit.state), <String>['1']);
    });

    test('akış hata verirse AnnouncementError', () async {
      cubit.startWatchingAnnouncements();
      repository.controller.addError(Exception('permission-denied'));
      await flush();
      expect(cubit.state, isA<AnnouncementError>());
      expect((cubit.state as AnnouncementError).message, contains('permission-denied'));
    });
  });

  group('filtreler', () {
    test('kategoriye göre filtreler', () async {
      await loadSeed();
      cubit.filterByType(AnnouncementType.event);
      expect(ids(cubit.state), <String>['2', '3']);
      expect((cubit.state as AnnouncementLoaded).selectedType, AnnouncementType.event);
    });

    test('takvim gününe göre filtreler (saat farkı önemsizdir)', () async {
      await loadSeed();
      cubit.filterByDate(DateTime(2026, 11, 13));
      expect(ids(cubit.state), <String>['1', '2']);
    });

    test('tarihsiz duyuru gün filtresinde çökmez ve listelenmez', () async {
      await loadSeed();
      cubit.filterByDate(DateTime(2026, 11, 20));
      expect(ids(cubit.state), <String>['3']);
    });

    test('gün + kategori filtresi birlikte çalışır', () async {
      await loadSeed();
      cubit.filterByDate(DateTime(2026, 11, 13));
      cubit.filterByType(AnnouncementType.exam);
      expect(ids(cubit.state), <String>['1']);
    });

    test('filtre temizlenince diğer filtre korunur', () async {
      await loadSeed();
      cubit.filterByDate(DateTime(2026, 11, 13));
      cubit.filterByType(AnnouncementType.event);
      expect(ids(cubit.state), <String>['2']);

      cubit.filterByDate(null);
      final state = cubit.state as AnnouncementLoaded;
      expect(state.selectedDate, isNull);
      expect(state.selectedType, AnnouncementType.event);
      expect(ids(state), <String>['2', '3']);

      cubit.filterByType(null);
      expect(ids(cubit.state), <String>['1', '2', '3', '4']);
    });

    test('veri yüklenmeden filtre çağrısı yok sayılır', () {
      cubit.filterByType(AnnouncementType.exam);
      cubit.filterByDate(DateTime(2026));
      expect(cubit.state, const AnnouncementInitial());
    });
  });

  group('addAnnouncement', () {
    test('duyuru depoya yazılır', () async {
      await cubit.addAnnouncement(_a('9', AnnouncementType.exam, nov13));
      expect(repository.created.single.id, '9');
    });

    test('yazma hatası AnnouncementError olur', () async {
      repository.error = Exception('yetkisiz');
      await cubit.addAnnouncement(_a('9', AnnouncementType.exam, nov13));
      expect(cubit.state, isA<AnnouncementError>());
    });

    test('başlıksız duyuru depoya gönderilmez', () async {
      await cubit.addAnnouncement(const AnnouncementEntity(
        id: 'x',
        title: '  ',
        content: 'c',
        type: AnnouncementType.general,
        authorName: 'a',
      ));
      expect(repository.created, isEmpty);
      expect(cubit.state, isA<AnnouncementError>());
    });
  });

  group('sendCrisisBroadcast (Anlık Kriz Yayını)', () {
    test('Sending → SentSuccess → önceki liste geri gelir', () async {
      final loaded = await loadSeed();
      emitted.clear();

      await cubit.sendCrisisBroadcast(title: ' Deprem Tatbikatı ', message: ' Binayı boşaltın ', targetCourseId: 'course-101');
      await flush();

      expect(emitted, <AnnouncementState>[const CrisisPushSending(), const CrisisPushSentSuccess(), loaded]);
      expect(repository.pushes.single, <String, String?>{
        'title': 'Deprem Tatbikatı',
        'body': 'Binayı boşaltın',
        'target': 'course-101',
      });
    });

    test('hedef ders verilmezse tüm kampüse gider (target null)', () async {
      await cubit.sendCrisisBroadcast(title: 'Kampüs kapalı', message: 'Kar tatili');
      expect(repository.pushes.single['target'], isNull);
    });

    test('boş başlık/mesaj gönderilmez', () async {
      await cubit.sendCrisisBroadcast(title: '', message: 'x');
      expect(repository.pushes, isEmpty);
      expect(cubit.state, isA<AnnouncementError>());
    });

    test('FCM hatası AnnouncementError olur', () async {
      repository.error = Exception('fcm down');
      await cubit.sendCrisisBroadcast(title: 'A', message: 'B');
      expect(cubit.state, isA<AnnouncementError>());
    });
  });

  test('close() akış aboneliğini iptal eder', () async {
    cubit.startWatchingAnnouncements();
    await flush();
    expect(repository.controller.hasListener, isTrue);
    await cubit.close();
    expect(repository.controller.hasListener, isFalse);
  });
}
