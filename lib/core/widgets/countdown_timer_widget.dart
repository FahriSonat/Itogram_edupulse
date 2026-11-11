import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';

/// [CountdownTimerWidget] dispose güvenli ortak geri sayım sayacıdır:
/// - Ders başlangıcına kalan süre (Modül 1.1)
/// - Ödev son teslim geri sayımı (Modül 1.3)
/// - 60 saniyelik canlı QR/PIN sayacı (Modül 2.1)
///
/// [targetDateTime] verilirse her saniye `DateTime.now()` ile yeniden hesaplanır
/// (uygulama arka plana alınsa bile kayma olmaz); aksi halde [initialSeconds]'tan
/// geri sayılır. Süre dolduğunda [onFinished] yalnızca bir kez çağrılır.
/// Timer `dispose` içinde iptal edilir ve her tikte `mounted` kontrol edilir.
class CountdownTimerWidget extends StatefulWidget {
  const CountdownTimerWidget({
    super.key,
    this.targetDateTime,
    this.initialSeconds,
    this.onFinished,
    this.isCompact = false,
    this.showClockFormat = false,
    this.customBuilder,
  }) : assert(
         targetDateTime != null || initialSeconds != null,
         'Either targetDateTime or initialSeconds must be provided',
       );

  final DateTime? targetDateTime;
  final int? initialSeconds;
  final VoidCallback? onFinished;
  final bool isCompact;

  /// true → `SS:DD:SS` (ör. 01:05:09), false → "1 sa 5 dk kaldı".
  final bool showClockFormat;
  final Widget Function(BuildContext context, Duration remaining, bool isExpired)? customBuilder;

  /// `Saat:Dakika:Saniye` biçimi (ör. `01:05:09`).
  static String formatClock(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(safe.inHours)}:${two(safe.inMinutes.remainder(60))}:${two(safe.inSeconds.remainder(60))}';
  }

  /// İnsan okunur kalan süre (ör. "2 sa 15 dk kaldı", "45 saniye kaldı").
  static String formatHuman(Duration d) {
    if (d <= Duration.zero) return AppStrings.countdownExpired;
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (days > 0) return '$days gün $hours sa kaldı';
    if (d.inHours > 0) return '${d.inHours} sa $minutes dk kaldı';
    if (minutes > 0) return '$minutes dk ${seconds.toString().padLeft(2, '0')} sn kaldı';
    return '$seconds saniye kaldı';
  }

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  late Duration _remaining;
  bool _hasFinishedFired = false;

  @override
  void initState() {
    super.initState();
    _initDuration();
    _startTimer();
  }

  void _initDuration() {
    if (widget.targetDateTime != null) {
      final diff = widget.targetDateTime!.difference(DateTime.now());
      _remaining = diff.isNegative ? Duration.zero : diff;
    } else {
      final seconds = widget.initialSeconds ?? 60;
      _remaining = Duration(seconds: seconds < 0 ? 0 : seconds);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (widget.targetDateTime != null) {
          final diff = widget.targetDateTime!.difference(DateTime.now());
          _remaining = diff.isNegative ? Duration.zero : diff;
        } else {
          final next = _remaining - const Duration(seconds: 1);
          _remaining = next.isNegative ? Duration.zero : next;
        }
      });

      if (_remaining == Duration.zero) {
        timer.cancel();
        _notifyFinished();
      }
    });
  }

  void _notifyFinished() {
    if (_hasFinishedFired) return;
    _hasFinishedFired = true;
    widget.onFinished?.call();
  }

  @override
  void didUpdateWidget(covariant CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetDateTime != widget.targetDateTime || oldWidget.initialSeconds != widget.initialSeconds) {
      _hasFinishedFired = false;
      _initDuration();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;

    if (widget.customBuilder != null) {
      return widget.customBuilder!(context, _remaining, isExpired);
    }

    return _buildDefaultBadge(context, isExpired);
  }

  Widget _buildDefaultBadge(BuildContext context, bool isExpired) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isUrgent = _remaining.inSeconds <= 10 && !isExpired;
    final Color badgeColor = (isExpired || isUrgent) ? AppColors.criticalAbsenceRed : AppColors.accentLight;
    final Color bgColor = badgeColor.withValues(alpha: isDark ? 0.2 : 0.12);
    final label = isExpired
        ? AppStrings.countdownExpired
        : (widget.showClockFormat
              ? CountdownTimerWidget.formatClock(_remaining)
              : CountdownTimerWidget.formatHuman(_remaining));

    return Semantics(
      liveRegion: false,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? AppDimensions.p8 : AppDimensions.p12,
            vertical: widget.isCompact ? AppDimensions.p4 : AppDimensions.p6,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppDimensions.radiusFull,
            border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpired ? Icons.timer_off_rounded : Icons.timer_outlined,
                size: widget.isCompact ? 13 : 16,
                color: badgeColor,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.isCompact ? 11 : 13,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
