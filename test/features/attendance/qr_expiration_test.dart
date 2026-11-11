// Kural 1 Testi (60 Sn Yoklama Kalkanı):
// Üretilen QR/PIN kodu 59. saniyede kabul edilmeli, 61. saniyede
// ExpiredQrPinException fırlatarak öğrencinin yoklama vermesini engellemelidir.
//
// Gerçek Firebase'e bağlanmamak için Firestore, bellekte çalışan sahte (fake)
// sınıflarla taklit edilir. Projedeki equatable ^3 sürümü fake_cloud_firestore
// ile uyumsuz olduğu için bu sınıflar flutter_test'in Fake yapısıyla yazıldı.

// Test taklitleri Firestore sınıflarını implement etmek zorunda:
// ignore_for_file: subtype_of_sealed_class, must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:itogram_edupulse/features/attendance/data/models/attendance_session_model.dart';

const String _courseId = 'course-101';
const String _sessionId = 'sess-1';
const String _studentId = 'uid-1';
const String _pin = '4821';
const String _qrToken = 'EDUPULSE|$_courseId|$_sessionId|$_pin';
const String _sessionPath = 'courses/$_courseId/attendance_sessions/$_sessionId';
const String _recordPath = 'courses/$_courseId/attendance_records/$_studentId';

void main() {
  late _FakeFirestore firestore;
  late AttendanceRemoteDataSourceImpl dataSource;

  setUp(() {
    firestore = _FakeFirestore();
    dataSource = AttendanceRemoteDataSourceImpl(firestore: firestore);
    firestore.docs['users/$_studentId'] = <String, dynamic>{
      'fullName': 'Merve Kedersiz',
      'studentOrStaffNo': '20261234',
      'role': 'student',
    };
    firestore.docs['courses/$_courseId'] = <String, dynamic>{
      'courseName': 'Mobil Programlama',
    };
  });

  /// Kod [secondsAgo] saniye önce üretilmiş gibi bir yoklama oturumu kurar.
  void seedSession({required int secondsAgo, bool isActive = true}) {
    final DateTime createdAt =
        DateTime.now().subtract(Duration(seconds: secondsAgo));
    firestore.docs[_sessionPath] = <String, dynamic>{
      'courseId': _courseId,
      'pinCode': _pin,
      'qrCodeToken': _qrToken,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt':
          Timestamp.fromDate(createdAt.add(const Duration(seconds: 60))),
      'studentStatusMap': <String, dynamic>{},
    };
  }

  /// Öğrencinin PIN veya QR ile yoklama vermesi.
  /// sessionId "courseId/sessionId" biçiminde verilir; böylece datasource
  /// oturumu doğrudan bulur.
  Future<void> submit({String code = _pin, String sessionId = _sessionId}) {
    return dataSource.submitLiveAttendance(
      sessionId: '$_courseId/$sessionId',
      studentUid: _studentId,
      code: code,
    );
  }

  String? studentStatus([String path = _sessionPath]) {
    final Map<String, dynamic>? statusMap =
        firestore.docs[path]?['studentStatusMap'] as Map<String, dynamic>?;
    return statusMap?[_studentId] as String?;
  }

  group('Kural 1: 60 saniyelik QR/PIN süresi', () {
    test('59. saniyede girilen PIN kabul edilir', () async {
      seedSession(secondsAgo: 59);

      await submit();

      expect(studentStatus(), 'present');
      expect(firestore.docs[_recordPath], isNotNull);
    });

    test('59. saniyede QR içeriği ile de yoklama verilebilir', () async {
      seedSession(secondsAgo: 59);

      await submit(code: _qrToken);

      expect(studentStatus(), 'present');
    });

    test('61. saniyede ExpiredQrPinException fırlatılır', () async {
      seedSession(secondsAgo: 61);

      await expectLater(submit(), throwsA(isA<ExpiredQrPinException>()));
    });

    test('süresi dolan kodla yoklama kaydı OLUŞMAZ', () async {
      seedSession(secondsAgo: 61);

      await expectLater(submit(), throwsA(isA<ExpiredQrPinException>()));
      expect(studentStatus(), isNull);
      expect(firestore.docs.containsKey(_recordPath), isFalse);
    });

    test('süre dolmasa bile eğitmen oturumu kapattıysa reddedilir', () async {
      seedSession(secondsAgo: 10, isActive: false);

      await expectLater(submit(), throwsA(isA<ExpiredQrPinException>()));
    });

    test('var olmayan oturuma yoklama verilemez', () async {
      await expectLater(submit(), throwsA(isA<ExpiredQrPinException>()));
    });

    test('süresi geçerli ama PIN yanlışsa reddedilir (süre hatası değil)',
        () async {
      seedSession(secondsAgo: 10);

      await expectLater(
        submit(code: '0000'),
        throwsA(
          allOf(isA<Exception>(), isNot(isA<ExpiredQrPinException>())),
        ),
      );
      expect(studentStatus(), isNull);
    });

    test(
      'kod boş gönderilirse yoklama reddedilir',
      () async {
        seedSession(secondsAgo: 10);

        await expectLater(submit(code: ''), throwsA(isA<Exception>()));
        expect(studentStatus(), isNull);
      },
    );
  });

  group('Eğitmen yeni kod ürettiğinde', () {
    test('expiresAt tam olarak createdAt + 60 saniyedir', () async {
      final AttendanceSessionModel session =
          await dataSource.generateAttendanceSession(_courseId);

      expect(
        session.expiresAt.difference(session.createdAt),
        const Duration(seconds: 60),
      );
      expect(session.isActive, isTrue);
    });

    test('şartnameye göre PIN 4 haneli olmalıdır', () async {
      final AttendanceSessionModel session =
          await dataSource.generateAttendanceSession(_courseId);

      expect(session.pinCode, matches(RegExp(r'^\d{4}$')));
    });

    test('üretilen kodla süre dolmadan yoklama verilebilir', () async {
      final AttendanceSessionModel session =
          await dataSource.generateAttendanceSession(_courseId);

      await submit(code: session.pinCode, sessionId: session.sessionId);

      expect(
        studentStatus(
          'courses/$_courseId/attendance_sessions/${session.sessionId}',
        ),
        'present',
      );
    });
  });

  group('Firestore transaction kuralı', () {
    test('transaction içinde tüm okumalar yazmalardan önce yapılır', () async {
      // _FakeTransaction gerçek Firestore gibi yazmadan sonra okumaya izin
      // vermez (strictTransactions varsayılan olarak açık).
      seedSession(secondsAgo: 10);

      await expectLater(submit(), completes);
    });
  });
}

// ---------------------------------------------------------------------------
// Bellek içi sahte Firestore
// ---------------------------------------------------------------------------

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> docs =
      <String, Map<String, dynamic>>{};

  /// true ise gerçek Firestore gibi "yazmadan sonra okuma" yasaklanır.
  bool strictTransactions = true;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _FakeCollection(this, collectionPath);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final _FakeTransaction transaction = _FakeTransaction(this);
    final T result = await transactionHandler(transaction);
    transaction.commit();
    return result;
  }
}

// Not: generateAttendanceSession içindeki öğrenci listesi hazırlığı
// (collection get / where / batch) bu sahte sınıflarda desteklenmez;
// datasource o adımı try/catch ile atladığı için Kural 1 testlerini etkilemez.
class _FakeCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _FakeCollection(this._store, this._path);

  final _FakeFirestore _store;
  final String _path;
  static int _autoId = 0;

  @override
  String get path => _path;

  @override
  String get id => _path.split('/').last;

  @override
  DocumentReference<Map<String, dynamic>>? get parent {
    final int slash = _path.lastIndexOf('/');
    return slash == -1 ? null : _FakeDocument(_store, _path.substring(0, slash));
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _FakeDocument(_store, '$_path/${path ?? 'auto-${_autoId++}'}');
}

class _FakeDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocument(this._store, this.path);

  final _FakeFirestore _store;

  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  FirebaseFirestore get firestore => _store;

  @override
  CollectionReference<Map<String, dynamic>> get parent =>
      _FakeCollection(_store, path.substring(0, path.lastIndexOf('/')));

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async =>
      _FakeSnapshot(_store.docs[path]);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    final bool merge = options?.merge ?? false;
    _store.docs[path] = <String, dynamic>{
      if (merge) ...?_store.docs[path],
      ...data,
    };
  }
}

class _FakeSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeSnapshot(this._data);

  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() =>
      _data == null ? null : Map<String, dynamic>.of(_data);
}

class _FakeTransaction extends Fake implements Transaction {
  _FakeTransaction(this._store);

  final _FakeFirestore _store;
  final List<void Function()> _pendingWrites = <void Function()>[];

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    if (_store.strictTransactions && _pendingWrites.isNotEmpty) {
      throw StateError(
        'Firestore transactions require all reads to be executed before all writes.',
      );
    }
    return _FakeSnapshot(_store.docs[documentReference.path])
        as DocumentSnapshot<T>;
  }

  @override
  Transaction update(
    DocumentReference<Object?> documentReference,
    Map<Object, Object?> data,
  ) {
    _pendingWrites.add(() {
      final Map<String, dynamic> current =
          _store.docs[documentReference.path] ?? <String, dynamic>{};
      _store.docs[documentReference.path] = <String, dynamic>{
        ...current,
        for (final MapEntry<Object, Object?> e in data.entries)
          e.key.toString(): e.value,
      };
    });
    return this;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    _pendingWrites.add(() {
      _store.docs[documentReference.path] =
          Map<String, dynamic>.of(data as Map<String, dynamic>);
    });
    return this;
  }

  void commit() {
    for (final void Function() write in _pendingWrites) {
      write();
    }
  }
}
