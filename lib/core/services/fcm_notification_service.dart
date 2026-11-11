import 'package:equatable/equatable.dart';

import '../constants/firestore_paths.dart';
import '../enums/user_role.dart';
import 'local_storage_service.dart';

/// Bildirim kategorisi (ikon ve renk seçimi için).
enum NotificationKind {
  info,
  crisis,
  announcement,
  assignment,
  grade,
  absence,
  forum;

  static NotificationKind fromJson(String? value) =>
      NotificationKind.values.firstWhere((k) => k.name == value, orElse: () => NotificationKind.info);
}

/// Uygulama içi bildirim.
class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationKind kind;

  /// Belirli bir kullanıcıya gönderildiyse onun uid'i.
  final String? targetUid;

  /// Belirli bir role (ör. tüm öğrenciler) gönderildiyse o rol. İkisi de null ise herkese.
  final UserRole? targetRole;
  final DateTime createdAt;
  final List<String> readBy;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.targetUid,
    this.targetRole,
    required this.createdAt,
    this.readBy = const [],
  });

  bool isReadBy(String uid) => readBy.contains(uid);

  bool isVisibleTo({required String uid, required UserRole role}) {
    if (targetUid != null) return targetUid == uid;
    if (targetRole != null) return targetRole == role;
    return true;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    kind: NotificationKind.fromJson(json['type'] as String?),
    targetUid: json['targetUid'] as String?,
    targetRole: json['targetRole'] == null ? null : UserRole.fromJson(json['targetRole'] as String?),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    readBy: (json['readBy'] as List<dynamic>? ?? const []).cast<String>(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': kind.name,
    'targetUid': targetUid,
    'targetRole': targetRole?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'readBy': readBy,
  };

  @override
  List<Object?> get props => [id, title, body, kind, targetUid, targetRole, createdAt, readBy];
}

/// [NotificationService] anlık bildirimleri (FCM benzeri) uygulama içinde iletir.
///
/// Kriz yayınları, devamsızlık uyarıları, yeni ödev ve not bildirimleri
/// hedef kullanıcının bildirim kutusuna düşer ve üst bardaki zil rozetinde
/// okunmamış sayısı görünür. Gerçek push (Firebase Cloud Messaging) için bu
/// sınıfın [send] metodu bir FCM çağrısıyla genişletilebilir.
class NotificationService {
  NotificationService(this._storage);

  final LocalStorageService _storage;

  Stream<List<AppNotification>> watchFor({required String uid, required UserRole role}) {
    return _storage.watch(FirestorePaths.notifications).map((docs) {
      final list = docs.map(AppNotification.fromJson).where((n) => n.isVisibleTo(uid: uid, role: role)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> send({
    required String title,
    required String body,
    NotificationKind kind = NotificationKind.info,
    String? targetUid,
    UserRole? targetRole,
  }) {
    final notification = AppNotification(
      id: _storage.generateId('n'),
      title: title,
      body: body,
      kind: kind,
      targetUid: targetUid,
      targetRole: targetRole,
      createdAt: DateTime.now(),
    );
    return _storage.upsert(FirestorePaths.notifications, notification.toJson());
  }

  Future<void> markAllRead({required String uid, required UserRole role}) async {
    final updated = <Map<String, dynamic>>[];
    for (final doc in _storage.getAll(FirestorePaths.notifications)) {
      final n = AppNotification.fromJson(doc);
      if (n.isVisibleTo(uid: uid, role: role) && !n.isReadBy(uid)) {
        updated.add({
          ...doc,
          'readBy': [...n.readBy, uid],
        });
      }
    }
    if (updated.isNotEmpty) {
      await _storage.upsertAll(FirestorePaths.notifications, updated);
    }
  }
}
