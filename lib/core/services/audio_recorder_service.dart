/// [AudioRecorderService] eğitmenin sesli geri bildirim kaydını soyutlar.
///
/// Ses kaydı mikrofon izni ve platforma özel eklenti (ör. `record`) gerektirir.
/// Bu sürümde yerleşik bir kayıt motoru yoktur: [isSupported] false döner ve
/// arayüz mikrofon düğmesini devre dışı bırakır; yazılı geri bildirim her
/// platformda çalışır.
abstract class AudioRecorderService {
  bool get isSupported;

  Future<void> start();

  /// Kaydı bitirir ve kaydedilen sesin adresini döndürür.
  Future<String?> stop();
}

class UnsupportedAudioRecorderService implements AudioRecorderService {
  const UnsupportedAudioRecorderService();

  @override
  bool get isSupported => false;

  @override
  Future<void> start() async => throw UnsupportedError('Sesli geri bildirim bu sürümde desteklenmiyor.');

  @override
  Future<String?> stop() async => null;
}
