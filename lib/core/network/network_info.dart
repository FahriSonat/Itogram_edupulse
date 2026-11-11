import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;

  /// Cihazın aktif internet bağlantısını kontrol eder; çevrimdışı durumda
  /// yerel önbellek (LocalStorageService) verilerinin devreye girmesini sağlar.
  Future<T> executeWithOfflineFallback<T>({
    required Future<T> Function() onOnline,
    required Future<T> Function(LocalStorageService localStorage) onOffline,
  });
}

class NetworkInfoImpl implements NetworkInfo {
  final Duration checkInterval;
  final String lookupHost;
  final LocalStorageService _localStorageService;

  StreamController<bool>? _connectivityController;
  Timer? _pollingTimer;
  bool? _lastStatus;

  NetworkInfoImpl({
    this.checkInterval = const Duration(seconds: 10),
    this.lookupHost = 'google.com',
    LocalStorageService? localStorageService,
  }) : _localStorageService = localStorageService ?? LocalStorageService();

  @override
  Future<bool> get isConnected async {
    if (kIsWeb) {
      return true;
    }
    try {
      final result = await InternetAddress.lookup(lookupHost)
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    _connectivityController ??= StreamController<bool>.broadcast(
      onListen: _startMonitoring,
      onCancel: _stopMonitoring,
    );
    return _connectivityController!.stream;
  }

  @override
  Future<T> executeWithOfflineFallback<T>({
    required Future<T> Function() onOnline,
    required Future<T> Function(LocalStorageService localStorage) onOffline,
  }) async {
    if (await isConnected) {
      try {
        return await onOnline();
      } catch (_) {
        return await onOffline(_localStorageService);
      }
    }
    return await onOffline(_localStorageService);
  }

  void _startMonitoring() {
    _checkAndEmit();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(checkInterval, (_) => _checkAndEmit());
  }

  Future<void> _checkAndEmit() async {
    final currentStatus = await isConnected;
    if (_lastStatus != currentStatus) {
      _lastStatus = currentStatus;
      if (_connectivityController != null && !_connectivityController!.isClosed) {
        _connectivityController!.add(currentStatus);
      }
    }
  }

  void _stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void dispose() {
    _stopMonitoring();
    _connectivityController?.close();
    _connectivityController = null;
  }
}
