import 'dart:async';

import '../../../../core/services/file_picker_service.dart';

/// [AssignmentStorageDataSource] ödev dosyalarının depolamaya yüklenmesini soyutlar
/// (ör. Firebase Storage). Yükleme ilerlemesini 0.0 → 1.0 arasında yayınlar.
abstract class AssignmentStorageDataSource {
  /// Yükleme tamamlandığında dosyanın depolama yolunu döndürür.
  Future<String> uploadFile({
    required PickedFileInfo file,
    required String storagePath,
    required void Function(double progress) onProgress,
  });
}

/// Yerel backend implementasyonu: dosya içeriği cihaz dışına gönderilmez;
/// dosya adı ve boyutu teslim kaydına işlenir. İlerleme çubuğu, dosya boyutuna
/// orantılı bir aktarım süresiyle (1–3 sn) güncellenir.
class LocalAssignmentStorageDataSource implements AssignmentStorageDataSource {
  const LocalAssignmentStorageDataSource({this.minDuration = const Duration(milliseconds: 1200)});

  final Duration minDuration;

  static const Duration _maxDuration = Duration(seconds: 3);
  static const int _steps = 20;

  @override
  Future<String> uploadFile({
    required PickedFileInfo file,
    required String storagePath,
    required void Function(double progress) onProgress,
  }) async {
    final perMb = const Duration(milliseconds: 120) * (file.sizeBytes / (1024 * 1024));
    var total = minDuration + perMb;
    if (total > _maxDuration) total = _maxDuration;
    final stepDelay = total ~/ _steps;

    onProgress(0);
    for (var i = 1; i <= _steps; i++) {
      if (stepDelay > Duration.zero) await Future<void>.delayed(stepDelay);
      onProgress(i / _steps);
    }
    return 'local://$storagePath/${file.name}';
  }
}
