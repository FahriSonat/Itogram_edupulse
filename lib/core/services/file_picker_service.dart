import 'package:file_picker/file_picker.dart';

/// Seçilen dosyanın platformdan bağımsız özeti.
class PickedFileInfo {
  final String name;
  final int sizeBytes;

  /// Masaüstü / mobilde dosya yolu; web'de null'dır.
  final String? path;

  const PickedFileInfo({required this.name, required this.sizeBytes, this.path});

  /// "14.2 MB" biçiminde okunabilir boyut.
  String get readableSize => formatBytes(sizeBytes);

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// [FilePickerService] ödev teslimi ve forum fotoğrafı için dosya seçimini soyutlar.
abstract class FilePickerService {
  /// Ödev dosyası (pdf, zip, docx …). Kullanıcı vazgeçerse null.
  Future<PickedFileInfo?> pickDocument();

  /// Forum sorusu için fotoğraf. Kullanıcı vazgeçerse null.
  Future<PickedFileInfo?> pickImage();
}

/// `file_picker` paketiyle sistemin dosya seçicisini açar (Android, iOS, web, masaüstü).
class PlatformFilePickerService implements FilePickerService {
  const PlatformFilePickerService();

  /// Ödev teslimlerinde kabul edilen en büyük dosya (50 MB).
  static const int maxUploadBytes = 50 * 1024 * 1024;

  @override
  Future<PickedFileInfo?> pickDocument() => _pick(FileType.any, 'Teslim edilecek ödev dosyasını seçin');

  @override
  Future<PickedFileInfo?> pickImage() => _pick(FileType.image, 'Soruya eklenecek fotoğrafı seçin');

  Future<PickedFileInfo?> _pick(FileType type, String title) async {
    final file = await FilePicker.pickFile(type: type, dialogTitle: title);
    if (file == null) return null;
    final size = file.lengthSync() ?? await file.length() ?? 0;
    return PickedFileInfo(name: file.name, sizeBytes: size, path: file.path);
  }
}
