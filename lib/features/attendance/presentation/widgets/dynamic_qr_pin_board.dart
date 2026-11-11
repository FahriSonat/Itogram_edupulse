import 'dart:convert';
import 'package:flutter/material.dart';

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
            child: Semantics(
              label: 'Yoklama QR kodu',
              image: true,
              child: CustomPaint(
                key: ValueKey('qr_$qrToken'),
                size: const Size.square(170),
                painter: _QrCodePainter(data: qrToken, color: AppColors.textPrimaryLight),
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

/// Dış paket bağımlılığı olmadan ISO-18004 (Sürüm 1–4, ECC-L, Byte modu)
/// taranabilir QR matrisi çizen saf Dart `CustomPainter`.
class _QrCodePainter extends CustomPainter {
  _QrCodePainter({required this.data, required this.color});

  final String data;
  final Color color;

  late final List<List<bool>> _matrix = _QrMatrixEncoder.encode(data);

  @override
  void paint(Canvas canvas, Size size) {
    final n = _matrix.length;
    if (n == 0) return;
    final module = size.width / n;
    final paint = Paint()..color = color;

    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (_matrix[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(c * module, r * module, module + 0.15, module + 0.15),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

class _QrSpec {
  const _QrSpec(this.version, this.size, this.dataCodewords, this.ecCodewords, this.alignPos);

  final int version;
  final int size;
  final int dataCodewords;
  final int ecCodewords;
  final int? alignPos;
}

abstract final class _QrMatrixEncoder {
  static const List<_QrSpec> _specs = [
    _QrSpec(1, 21, 19, 7, null),
    _QrSpec(2, 25, 34, 10, 18),
    _QrSpec(3, 29, 55, 15, 22),
    _QrSpec(4, 33, 80, 20, 26),
  ];

  /// ECC Level L (01) + Mask 0 (000) için önceden hesaplanmış 15-bit format bilgisi.
  static const int _formatBitsMask0 = 0x77C4;

  static final List<int> _gfExp = _buildGfExp();
  static final List<int> _gfLog = _buildGfLog(_gfExp);

  static List<int> _buildGfExp() {
    final exp = List<int>.filled(512, 0);
    var v = 1;
    for (var i = 0; i < 255; i++) {
      exp[i] = v;
      exp[i + 255] = v;
      v <<= 1;
      if (v >= 256) v ^= 0x11D;
    }
    return exp;
  }

  static List<int> _buildGfLog(List<int> exp) {
    final log = List<int>.filled(256, 0);
    for (var i = 0; i < 255; i++) {
      log[exp[i]] = i;
    }
    return log;
  }

  static int _gfMul(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return _gfExp[_gfLog[a] + _gfLog[b]];
  }

  static List<int> _rsCompute(List<int> data, int ecCount) {
    var gen = <int>[1];
    for (var i = 0; i < ecCount; i++) {
      final factor = [1, _gfExp[i]];
      final next = List<int>.filled(gen.length + 1, 0);
      for (var j = 0; j < gen.length; j++) {
        for (var k = 0; k < factor.length; k++) {
          next[j + k] ^= _gfMul(gen[j], factor[k]);
        }
      }
      gen = next;
    }

    final buf = List<int>.filled(data.length + ecCount, 0);
    for (var i = 0; i < data.length; i++) {
      buf[i] = data[i];
    }
    for (var i = 0; i < data.length; i++) {
      final coef = buf[i];
      if (coef == 0) continue;
      for (var j = 0; j < gen.length; j++) {
        buf[i + j] ^= _gfMul(gen[j], coef);
      }
    }
    return buf.sublist(data.length);
  }

  static List<List<bool>> encode(String input) {
    var bytes = utf8.encode(input);
    if (bytes.length > 78) {
      bytes = bytes.sublist(0, 78);
    }

    final spec = _specs.firstWhere(
      (s) => bytes.length <= s.dataCodewords - 2,
      orElse: () => _specs.last,
    );

    final bits = <int>[];
    void pushBits(int val, int len) {
      for (var i = len - 1; i >= 0; i--) {
        bits.add((val >> i) & 1);
      }
    }

    // Byte modu (0100) + 8-bit karakter uzunluğu + veri bitleri + sonlandırıcı.
    pushBits(0x4, 4);
    pushBits(bytes.length, 8);
    for (final b in bytes) {
      pushBits(b, 8);
    }
    final maxBits = spec.dataCodewords * 8;
    for (var i = 0; i < 4 && bits.length < maxBits; i++) {
      bits.add(0);
    }
    while (bits.length % 8 != 0) {
      bits.add(0);
    }

    final dataCodewords = <int>[];
    for (var i = 0; i < bits.length; i += 8) {
      var byte = 0;
      for (var j = 0; j < 8; j++) {
        byte = (byte << 1) | bits[i + j];
      }
      dataCodewords.add(byte);
    }

    const padBytes = [0xEC, 0x11];
    var padIndex = 0;
    while (dataCodewords.length < spec.dataCodewords) {
      dataCodewords.add(padBytes[padIndex % 2]);
      padIndex++;
    }

    final ecCodewords = _rsCompute(dataCodewords, spec.ecCodewords);
    final allCodewords = [...dataCodewords, ...ecCodewords];
    final stream = <int>[];
    for (final cw in allCodewords) {
      for (var b = 7; b >= 0; b--) {
        stream.add((cw >> b) & 1);
      }
    }

    final n = spec.size;
    final modules = List.generate(n, (_) => List<bool>.filled(n, false));
    final reserved = List.generate(n, (_) => List<bool>.filled(n, false));

    void setModule(int r, int c, bool dark) {
      modules[r][c] = dark;
      reserved[r][c] = true;
    }

    void drawFinder(int top, int left) {
      for (var dr = -1; dr <= 7; dr++) {
        for (var dc = -1; dc <= 7; dc++) {
          final r = top + dr;
          final c = left + dc;
          if (r < 0 || r >= n || c < 0 || c >= n) continue;
          final inBorder = dr == -1 || dr == 7 || dc == -1 || dc == 7;
          final isDark = !inBorder &&
              ((dr == 0 || dr == 6 || dc == 0 || dc == 6) ||
                  (dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4));
          setModule(r, c, isDark);
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(0, n - 7);
    drawFinder(n - 7, 0);

    if (spec.alignPos != null) {
      final center = spec.alignPos!;
      for (var dr = -2; dr <= 2; dr++) {
        for (var dc = -2; dc <= 2; dc++) {
          final isDark = dr.abs() == 2 || dc.abs() == 2 || (dr == 0 && dc == 0);
          setModule(center + dr, center + dc, isDark);
        }
      }
    }

    for (var i = 8; i < n - 8; i++) {
      final dark = i.isEven;
      setModule(6, i, dark);
      setModule(i, 6, dark);
    }

    // Zorunlu koyu modül ve 15-bit format alanı (maske 0, ECC L).
    setModule(n - 8, 8, true);
    for (var i = 0; i < 15; i++) {
      final bit = ((_formatBitsMask0 >> i) & 1) == 1;
      if (i < 6) {
        setModule(i, 8, bit);
      } else if (i < 8) {
        setModule(i + 1, 8, bit);
      } else {
        setModule(n - 15 + i, 8, bit);
      }
      if (i < 8) {
        setModule(8, n - i - 1, bit);
      } else if (i < 9) {
        setModule(8, 15 - i, bit);
      } else {
        setModule(8, 15 - i - 1, bit);
      }
    }

    // Veri bitlerini zig-zag yerleştir ve Maske 0 ((r + c) % 2 == 0) uygula.
    var bitIdx = 0;
    var upward = true;
    for (var right = n - 1; right >= 1; right -= 2) {
      if (right == 6) right = 5;
      for (var step = 0; step < n; step++) {
        final r = upward ? n - 1 - step : step;
        for (var dx = 0; dx < 2; dx++) {
          final c = right - dx;
          if (reserved[r][c]) continue;
          final rawBit = bitIdx < stream.length ? stream[bitIdx++] == 1 : false;
          final mask = (r + c).isEven;
          modules[r][c] = rawBit ^ mask;
        }
      }
      upward = !upward;
    }

    return modules;
  }
}
