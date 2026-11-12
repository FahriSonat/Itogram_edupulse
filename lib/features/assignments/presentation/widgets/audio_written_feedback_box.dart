import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// [AudioWrittenFeedbackBox] eğitmenin **sesli / yazılı geribildirim** bileşenidir.
///
/// - Eğitmen ([isInstructor] = true): yazılı geribildirim alanı + mikrofonla
///   ses kaydı başlat/durdur ([onStartRecording] / [onStopRecording]).
/// - Öğrenci: yazılı geribildirimi okur, sesli notu dinler ([onPlayAudio]).
///
/// Kayıt/oynatma `AudioRecorderService` tarafından yapılır; bu bileşen
/// yalnızca durumu ([isRecording], [isPlaying]) görselleştirir.
class AudioWrittenFeedbackBox extends StatefulWidget {
  const AudioWrittenFeedbackBox({
    super.key,
    this.writtenFeedback,
    this.audioFeedbackUrl,
    this.audioDurationLabel,
    this.isInstructor = false,
    this.onWrittenFeedbackChanged,
    this.onStartRecording,
    this.onStopRecording,
    this.onPlayAudio,
    this.onDeleteAudio,
    this.isRecording = false,
    this.isPlaying = false,
  });

  final String? writtenFeedback;
  final String? audioFeedbackUrl;

  /// Ses kaydının süresi (ör. "0:45"); bilinmiyorsa gösterilmez.
  final String? audioDurationLabel;
  final bool isInstructor;
  final ValueChanged<String>? onWrittenFeedbackChanged;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onDeleteAudio;
  final bool isRecording;
  final bool isPlaying;

  @override
  State<AudioWrittenFeedbackBox> createState() => _AudioWrittenFeedbackBoxState();
}

class _AudioWrittenFeedbackBoxState extends State<AudioWrittenFeedbackBox> {
  late final TextEditingController _controller = TextEditingController(text: widget.writtenFeedback ?? '');

  @override
  void didUpdateWidget(covariant AudioWrittenFeedbackBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dışarıdan gelen değer değiştiyse (ör. kayıt yüklendi) alanı senkronla.
    final incoming = widget.writtenFeedback ?? '';
    if (incoming != (oldWidget.writtenFeedback ?? '') && incoming != _controller.text) {
      _controller.text = incoming;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final hasAudio = widget.audioFeedbackUrl != null && widget.audioFeedbackUrl!.isNotEmpty;

    final String audioSubtitle;
    if (widget.isRecording) {
      audioSubtitle = 'Kaydediliyor... durdurmak için dokunun';
    } else if (hasAudio) {
      audioSubtitle = widget.audioDurationLabel == null
          ? 'Dinlemek için dokunun'
          : '${widget.audioDurationLabel} • Dinlemek için dokunun';
    } else {
      audioSubtitle = widget.isInstructor ? 'Mikrofonla sesli not kaydedin' : 'Sesli not eklenmemiş';
    }

    return Container(
      padding: AppDimensions.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: AppDimensions.radius16,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_outlined, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Eğitmen Değerlendirmesi & Geri Bildirim',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p12),
          if (widget.isInstructor)
            TextField(
              key: const ValueKey('written_feedback_field'),
              controller: _controller,
              maxLines: 3,
              onChanged: widget.onWrittenFeedbackChanged,
              decoration: const InputDecoration(
                labelText: 'Yazılı Geribildirim',
                hintText: 'Öğrenciye özel yazılı geribildiriminizi giriniz...',
                alignLabelWithHint: true,
              ),
            )
          else
            Text(
              (widget.writtenFeedback != null && widget.writtenFeedback!.isNotEmpty)
                  ? widget.writtenFeedback!
                  : 'Henüz yazılı bir geribildirim eklenmemiş.',
              style: TextStyle(color: muted, fontSize: 13, height: 1.4),
            ),
          const SizedBox(height: AppDimensions.p16),
          // Sesli geribildirim
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isRecording
                  ? AppColors.criticalAbsenceRed.withValues(alpha: isDark ? 0.18 : 0.06)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
              borderRadius: AppDimensions.radius12,
              border: Border.all(
                color: widget.isRecording
                    ? AppColors.criticalAbsenceRed.withValues(alpha: 0.6)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: widget.isPlaying ? 'Duraklat' : 'Sesli notu dinle',
                  icon: Icon(
                    widget.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: hasAudio ? primaryColor : muted.withValues(alpha: 0.5),
                    size: 32,
                  ),
                  onPressed: hasAudio && !widget.isRecording ? widget.onPlayAudio : null,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.isRecording) ...[const _RecordingDot(), const SizedBox(width: 6)],
                          const Flexible(
                            child: Text(
                              'Sesli Öğretmen Notu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        audioSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                ),
                if (widget.isInstructor) ...[
                  if (hasAudio && !widget.isRecording && widget.onDeleteAudio != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.criticalAbsenceRed),
                      tooltip: 'Sesli notu sil',
                      onPressed: widget.onDeleteAudio,
                    ),
                  IconButton(
                    icon: Icon(
                      widget.isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                      color: widget.isRecording ? AppColors.criticalAbsenceRed : primaryColor,
                    ),
                    onPressed: widget.isRecording ? widget.onStopRecording : widget.onStartRecording,
                    tooltip: widget.isRecording ? 'Kaydı Durdur' : 'Ses Kaydı Başlat',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kayıt sırasında yanıp sönen kırmızı nokta.
class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: AppColors.criticalAbsenceRed, shape: BoxShape.circle),
      ),
    );
  }
}
