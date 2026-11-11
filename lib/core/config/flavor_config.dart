/// Uygulamanın veri kaynağı.
enum BackendType {
  /// Veriler cihazda (SharedPreferences) saklanır; kurulum gerektirmez.
  local,
}

/// [FlavorConfig] derleme ortamına göre değişen ayarlar.
class FlavorConfig {
  final String name;
  final BackendType backend;

  /// Demo hesaplarının giriş ekranında gösterilip gösterilmeyeceği.
  final bool showDemoAccounts;

  const FlavorConfig({required this.name, required this.backend, required this.showDemoAccounts});

  static const FlavorConfig development = FlavorConfig(
    name: 'development',
    backend: BackendType.local,
    showDemoAccounts: true,
  );

  static FlavorConfig current = development;
}
