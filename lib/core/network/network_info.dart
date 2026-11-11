/// [NetworkInfo] bağlantı durumunu soyutlar.
///
/// Yerel backend ([LocalStorageService]) çevrim dışı çalıştığı için varsayılan
/// implementasyon her zaman bağlı döner. Uzak bir backend (Firebase vb.)
/// eklendiğinde gerçek bağlantı kontrolü bu arayüzün arkasına konabilir.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class LocalNetworkInfo implements NetworkInfo {
  const LocalNetworkInfo();

  @override
  Future<bool> get isConnected async => true;
}
