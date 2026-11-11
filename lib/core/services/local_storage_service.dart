import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/firestore_paths.dart';
import '../error/exceptions.dart';
import 'demo_seed_data.dart';

/// [LocalStorageService] EduPulse'un cihaz üzerindeki doküman veritabanıdır.
///
/// Her koleksiyon ([FirestorePaths]) SharedPreferences'ta JSON listesi olarak
/// saklanır. Yazma işlemleri koleksiyona abone olan akışları ([watch])
/// tetikler; böylece ekranlar Firestore snapshot'larına benzer şekilde
/// reaktif olarak güncellenir. Web, masaüstü ve mobilde aynı şekilde çalışır.
class LocalStorageService {
  LocalStorageService(this._prefs);

  static const String _collectionPrefix = 'edupulse_db_';
  static const String _seedVersionKey = 'edupulse_db_seed_version';
  static const int _seedVersion = 1;

  final SharedPreferences _prefs;
  final Map<String, StreamController<List<Map<String, dynamic>>>> _controllers = {};
  final Random _random = Random();

  /// İlk açılışta (veya [resetDemoData] sonrası) demo verilerini yükler.
  Future<void> init() async {
    if (_prefs.getInt(_seedVersionKey) != _seedVersion) {
      await _seed();
    }
  }

  /// Tüm koleksiyonları silip demo verilerini baştan yükler.
  Future<void> resetDemoData() async {
    for (final collection in FirestorePaths.all) {
      await _prefs.remove('$_collectionPrefix$collection');
    }
    await _seed();
    for (final collection in FirestorePaths.all) {
      _notify(collection);
    }
  }

  Future<void> _seed() async {
    final seed = DemoSeedData.build(DateTime.now());
    for (final entry in seed.entries) {
      await _write(entry.key, entry.value);
    }
    await _prefs.setInt(_seedVersionKey, _seedVersion);
  }

  // ---------------------------------------------------------------------------
  // KOLEKSİYON İŞLEMLERİ
  // ---------------------------------------------------------------------------

  /// Koleksiyondaki tüm dokümanları döndürür.
  List<Map<String, dynamic>> getAll(String collection) {
    final raw = _prefs.getString('$_collectionPrefix$collection');
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      throw const CacheException('Yerel veri okunamadı (bozuk kayıt).');
    }
  }

  /// `id` alanına göre tek doküman döndürür.
  Map<String, dynamic>? getById(String collection, String id) {
    for (final doc in getAll(collection)) {
      if (doc['id'] == id) return doc;
    }
    return null;
  }

  /// Dokümanı ekler veya aynı `id` varsa günceller.
  Future<void> upsert(String collection, Map<String, dynamic> doc) async {
    final id = doc['id'];
    if (id is! String || id.isEmpty) {
      throw const CacheException('Kaydedilecek dokümanın kimliği (id) yok.');
    }
    final docs = getAll(collection);
    final index = docs.indexWhere((d) => d['id'] == id);
    if (index >= 0) {
      docs[index] = doc;
    } else {
      docs.add(doc);
    }
    await _write(collection, docs);
    _notify(collection);
  }

  /// Birden fazla dokümanı tek yazma işlemiyle ekler/günceller.
  Future<void> upsertAll(String collection, List<Map<String, dynamic>> newDocs) async {
    final docs = getAll(collection);
    for (final doc in newDocs) {
      final index = docs.indexWhere((d) => d['id'] == doc['id']);
      if (index >= 0) {
        docs[index] = doc;
      } else {
        docs.add(doc);
      }
    }
    await _write(collection, docs);
    _notify(collection);
  }

  Future<void> delete(String collection, String id) async {
    final docs = getAll(collection)..removeWhere((d) => d['id'] == id);
    await _write(collection, docs);
    _notify(collection);
  }

  Future<void> deleteWhere(String collection, bool Function(Map<String, dynamic> doc) test) async {
    final docs = getAll(collection)..removeWhere(test);
    await _write(collection, docs);
    _notify(collection);
  }

  /// Koleksiyonun güncel halini hemen, ardından her değişiklikte yayınlar.
  Stream<List<Map<String, dynamic>>> watch(String collection) {
    final controller = _controllers.putIfAbsent(
      collection,
      () => StreamController<List<Map<String, dynamic>>>.broadcast(),
    );
    return Stream<List<Map<String, dynamic>>>.multi((listener) {
      listener.add(getAll(collection));
      final sub = controller.stream.listen(listener.add, onError: listener.addError);
      listener.onCancel = sub.cancel;
    });
  }

  /// Benzersiz doküman kimliği üretir.
  String generateId([String prefix = 'doc']) {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = _random.nextInt(0x7fffffff).toRadixString(36);
    return '${prefix}_$ts$rnd';
  }

  // ---------------------------------------------------------------------------
  // BASİT ANAHTAR-DEĞER İŞLEMLERİ (oturum, tercih)
  // ---------------------------------------------------------------------------

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  // ---------------------------------------------------------------------------

  Future<void> _write(String collection, List<Map<String, dynamic>> docs) async {
    final ok = await _prefs.setString('$_collectionPrefix$collection', jsonEncode(docs));
    if (!ok) throw const CacheException('Veri cihaza kaydedilemedi.');
  }

  void _notify(String collection) {
    final controller = _controllers[collection];
    if (controller != null && controller.hasListener) {
      controller.add(getAll(collection));
    }
  }
}
