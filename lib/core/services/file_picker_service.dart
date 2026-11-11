import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PickedFileAttachment {
  final String name;
  final String? path;
  final Uint8List? bytes;
  final int sizeInBytes;
  final String? extension;

  const PickedFileAttachment({
    required this.name,
    this.path,
    this.bytes,
    required this.sizeInBytes,
    this.extension,
  });

  File? get file => path != null ? File(path!) : null;
}

class FilePickerService {
  final ImagePicker _imagePicker;

  FilePickerService({
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  /// Ödev teslimi için dosya seçimi (PDF, DOC, DOCX, ZIP, TXT, Görsel vb.)
  Future<PickedFileAttachment?> pickAssignmentFile({
    List<String> allowedExtensions = const [
      'pdf',
      'doc',
      'docx',
      'zip',
      'rar',
      'txt',
      'png',
      'jpg',
      'jpeg',
    ],
    bool loadBytes = false,
  }) async {
    final platformFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (platformFile == null) {
      return null;
    }

    final bytes = loadBytes ? await platformFile.readAsBytes() : null;
    final size = platformFile.lengthSync() ??
        await platformFile.length() ??
        (bytes?.length ?? 0);

    return PickedFileAttachment(
      name: platformFile.name,
      path: platformFile.path,
      bytes: bytes,
      sizeInBytes: size,
      extension: platformFile.extension,
    );
  }

  /// Forum veya profil için galeriden ya da kameradan fotoğraf seçimi
  Future<PickedFileAttachment?> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    final XFile? xFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    if (xFile == null) return null;

    final bytes = await xFile.readAsBytes();
    final extension = xFile.name.contains('.')
        ? xFile.name.split('.').last.toLowerCase()
        : 'jpg';

    return PickedFileAttachment(
      name: xFile.name,
      path: xFile.path,
      bytes: bytes,
      sizeInBytes: bytes.length,
      extension: extension,
    );
  }

  /// Sesli geri bildirim için ses dosyası seçimi
  Future<PickedFileAttachment?> pickAudioFile({bool loadBytes = false}) async {
    final platformFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
    );

    if (platformFile == null) {
      return null;
    }

    final bytes = loadBytes ? await platformFile.readAsBytes() : null;
    final size = platformFile.lengthSync() ??
        await platformFile.length() ??
        (bytes?.length ?? 0);

    return PickedFileAttachment(
      name: platformFile.name,
      path: platformFile.path,
      bytes: bytes,
      sizeInBytes: size,
      extension: platformFile.extension,
    );
  }

  Future<void> clearTemporaryFiles() async {
    await FilePicker.clearTemporaryFiles();
  }
}
