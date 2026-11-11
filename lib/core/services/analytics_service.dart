import 'package:flutter/foundation.dart';

/// [AnalyticsService] uygulama içi olayları kaydeder.
///
/// Şu an olaylar yalnızca debug konsoluna yazılır; Firebase Analytics gibi
/// bir sağlayıcı eklendiğinde [logEvent] gövdesi değiştirilmesi yeterlidir.
class AnalyticsService {
  const AnalyticsService();

  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) {
      debugPrint('[analytics] $name ${params.isEmpty ? '' : params}');
    }
  }

  void logScreen(String screenName) => logEvent('screen_view', {'screen': screenName});
}
