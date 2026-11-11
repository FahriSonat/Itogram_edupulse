import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/countdown_timer_widget.dart';

/// [DynamicQrPinBoard] eğitmenin **60 sn sayaçlı QR/PIN panosudur** (Kural 1).
///
/// [qrToken]'dan taranabilir gerçek bir QR kod üretir, 4 haneli [pinCode]'u
/// büyük hanelerle gösterir ve kodun geçerlilik süresini sayar. Süre
/// [expiresAt]'ten (tercih edilen; `AttendanceSessionEntity.expiresAt`) veya
/// [remainingSeconds]'tan hesaplanır. Süre dolduğunda [onExpireOrRefresh]
/// çağrılır; cubit yeni kodu üretip panoyu yeniden kurar.
class DynamicQrPinBoard extends StatelessWidget {
  const DynamicQrPinBoard({
    super.key,
    required this.pinCode,
    required this.qrToken,
    this.expiresAt,
    this.remainingSeconds = validitySeconds,
    this.onExpireOrRefresh,
    this.courseLabel,
  });

  /// Kural 1: kodun geçerlilik süresi.
  static const int validitySeconds = 60;

  final String pinCode;
  final String qrToken;
  final DateTime? expiresAt;
  final int remainingSeconds;
  final VoidCallback? onExpireOrRefresh;

  /// Pano başlığında gösterilecek ders etiketi (ör. "MOB101 • Flutter").
  final String? courseLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      padding: AppDimensions.paddingAll20,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : AppColors.primaryGradient,
        borderRadius: AppDimensions.radius20,
        border: isDark ? Border.all(color: AppColors.glowBlue.withValues(alpha: 0.35)) : null,
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.glowBlue : AppColors.primaryLight).withValues(alpha: isDark ? 0.18 : 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CountdownTimerWidget(
        targetDateTime: expiresAt,
        initialSeconds: expiresAt == null ? remainingSeconds : null,
        onFinished: onExpireOrRefresh,
        customBuilder: (context, remaining, isExpired) => _BoardContent(
          pinCode: pinCode,
          qrToken: qrToken,
          courseLabel: courseLabel,
          remaining: remaining,
          isExpired: isExpired,
        ),
      ),
    );
  }
}

class _BoardContent extends StatelessWidget {
  const _BoardContent({
    required this.pinCode,
    required this.qrToken,
    required this.courseLabel,
    required this.remaining,
    required this.isExpired,
  });

  final String pinCode;
  final String qrToken;
  final String? courseLabel;
  final Duration remaining;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final seconds = remaining.inSeconds.clamp(0, DynamicQrPinBoard.validitySeconds);
    final isUrgent = !isExpired && seconds <= 10;
    final progress = seconds / DynamicQrPinBoard.validitySeconds;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isExpired ? AppColors.warningAmber : AppColors.secondaryLight,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                courseLabel == null ? 'Canlı Yoklama Oturumu' : 'Canlı Yoklama • $courseLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: isExpired ? 'Kod yenileniyor' : 'Kodun geçerliliğine $seconds saniye kaldı',
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? AppColors.criticalAbsenceRed.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: AppDimensions.radiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        isExpired ? 'Yenileniyor...' : '$seconds sn',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.p12),
        ClipRRect(
          borderRadius: AppDimensions.radiusFull,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(isUrgent ? AppColors.criticalAbsenceRed : Colors.white),
          ),
        ),
        const SizedBox(height: AppDimensions.p16),
        // Dev QR kod — öğrencinin kamerasıyla okutulur.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: isExpired ? 0.35 : 1,
          child: Container(
            width: 190,
            height: 190,
            padding: const EdgeInsets.all(AppDimensions.p10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppDimensions.radius16,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: QrImageView(
              key: ValueKey('qr_$qrToken'),
              data: qrToken,
              version: QrVersions.auto,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              semanticsLabel: 'Yoklama QR kodu',
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimaryLight),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.p16),
        const Text(
          '4 Haneli Hızlı Katılım Kodu',
          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppDimensions.p8),
        Semantics(
          label: 'PIN kodu ${pinCode.split('').join(' ')}',
          child: ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final digit in pinCode.padRight(4, '-').substring(0, 4).split(''))
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 48,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: AppDimensions.radius12,
                        border: Border.all(color: Colors.white30, width: 1.5),
                      ),
                      child: Text(
                        digit,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.p12),
        const Text(
          'Kural 1: Kod 60 sn sonra geçersiz kalır ve otomatik yenilenir.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}
