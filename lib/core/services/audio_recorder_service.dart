import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

enum AudioRecorderState {
  idle,
  recording,
  paused,
  stopped,
  playing,
}

/// Modül 2.2 kapsamında eğitmenin öğrenci ödevine sesli geribildirim kaydedebilmesi
/// için mikrofon kaydı yapan, geçici ses dosyası oluşturan ve oynatan servistir.
class AudioRecorderService {
  AudioRecorderState _state = AudioRecorderState.idle;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  Timer? _playbackTimer;
  Duration _elapsed = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  String? _currentRecordingPath;

  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _playbackPositionController =
      StreamController<Duration>.broadcast();
  final StreamController<AudioRecorderState> _stateController =
      StreamController<AudioRecorderState>.broadcast();

  AudioRecorderState get state => _state;
  bool get isRecording => _state == AudioRecorderState.recording;
  bool get isPlaying => _state == AudioRecorderState.playing;
  Duration get elapsed => _elapsed;
  Duration get playbackPosition => _playbackPosition;
  String? get currentRecordingPath => _currentRecordingPath;

  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<Duration> get onPlaybackPositionChanged =>
      _playbackPositionController.stream;
  Stream<AudioRecorderState> get onStateChanged => _stateController.stream;

  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasMicrophonePermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Mikrofon kaydını başlatır ve geçici ses dosyasının yolunu döner.
  Future<String?> startRecording({String? customFileName}) async {
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Mikrofon izni verilmedi.');
    }

    await stopPlayback();

    final fileName = customFileName ??
        'feedback_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final tempDir = Directory.systemTemp;
    _currentRecordingPath = '${tempDir.path}/$fileName';

    _recordingStartTime = DateTime.now();
    _elapsed = Duration.zero;
    _updateState(AudioRecorderState.recording);

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingStartTime != null &&
          _state == AudioRecorderState.recording) {
        _elapsed = DateTime.now().difference(_recordingStartTime!);
        if (!_durationController.isClosed) {
          _durationController.add(_elapsed);
        }
      }
    });

    return _currentRecordingPath;
  }

  /// Aktif mikrofon kaydını durdurur ve geçici ses dosyasını oluşturur.
  Future<String?> stopRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _updateState(AudioRecorderState.stopped);

    if (_currentRecordingPath != null && !kIsWeb) {
      final file = File(_currentRecordingPath!);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
    }
    return _currentRecordingPath;
  }

  /// Kaydedilen veya indirilen sesli geribildirim dosyasını oynatır.
  Future<void> playRecording({
    String? filePathOrUrl,
    Duration? totalDuration,
  }) async {
    final target = filePathOrUrl ?? _currentRecordingPath;
    if (target == null || target.isEmpty) {
      throw Exception('Oynatılacak ses dosyası bulunamadı.');
    }

    if (_state == AudioRecorderState.recording) {
      await stopRecording();
    }

    _playbackPosition = Duration.zero;
    _updateState(AudioRecorderState.playing);
    await SystemSound.play(SystemSoundType.click);

    final maxDuration = totalDuration ??
        (_elapsed > Duration.zero ? _elapsed : const Duration(seconds: 5));

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_state != AudioRecorderState.playing) {
        timer.cancel();
        return;
      }
      _playbackPosition += const Duration(milliseconds: 500);
      if (!_playbackPositionController.isClosed) {
        _playbackPositionController.add(_playbackPosition);
      }
      if (_playbackPosition >= maxDuration) {
        stopPlayback();
      }
    });
  }

  /// Ses oynatmayı duraklatır.
  Future<void> pausePlayback() async {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (_state == AudioRecorderState.playing) {
      _updateState(AudioRecorderState.paused);
    }
  }

  /// Ses oynatmayı tamamen durdurur ve başa sarar.
  Future<void> stopPlayback() async {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackPosition = Duration.zero;
    if (!_playbackPositionController.isClosed) {
      _playbackPositionController.add(_playbackPosition);
    }
    if (_state == AudioRecorderState.playing ||
        _state == AudioRecorderState.paused) {
      _updateState(AudioRecorderState.stopped);
    }
  }

  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _elapsed = Duration.zero;
    _playbackPosition = Duration.zero;
    _updateState(AudioRecorderState.idle);

    if (_currentRecordingPath != null && !kIsWeb) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentRecordingPath = null;
    }
  }

  void _updateState(AudioRecorderState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void dispose() {
    _durationTimer?.cancel();
    _playbackTimer?.cancel();
    _durationController.close();
    _playbackPositionController.close();
    _stateController.close();
  }
}
