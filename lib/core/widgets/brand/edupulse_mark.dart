import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// EduPulse marka renkleri. Logo, uygulama ikonu ve splash aynı paleti kullanır.
abstract final class EduPulseBrand {
  static const Color blue = Color(0xFF2563EB);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color violet = Color(0xFF7C3AED);
  static const Color gold = Color(0xFFFBBF24);
  static const Color capShade = Color(0xFFC7D2FE);

  /// Rozetin gradyanı (sol üst mavi → sağ alt mor).
  static const LinearGradient badgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, indigo, violet],
    stops: [0.0, 0.55, 1.0],
  );

  /// "Pulse" yazısının gradyanı.
  static const LinearGradient wordmarkLight = LinearGradient(colors: [blue, violet]);
  static const LinearGradient wordmarkDark = LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)]);
}

/// [EduPulseMarkPainter] EduPulse'un özgün logo işaretidir: "Nabızlı Kep".
///
/// Mavi→mor yuvarlatılmış rozet içinde beyaz bir mezuniyet kepi; altında altın
/// sarısı bir nabız (EKG) çizgisi yükselir ve tepesiyle kepi "kaldırır".
/// Eğitim (Edu) + canlı takip (Pulse) tek bir sembolde birleşir.
///
/// - [pulseProgress]: nabız çizgisinin çizilmiş oranı (0..1) — açılış animasyonu.
/// - [fullBleed]: köşesiz kare zemin (iOS ikonları; köşeleri sistem keser).
class EduPulseMarkPainter extends CustomPainter {
  const EduPulseMarkPainter({this.pulseProgress = 1.0, this.fullBleed = false, this.contentScale = 1.0});

  final double pulseProgress;
  final bool fullBleed;

  /// Kep + nabız içeriğinin rozet içindeki ölçeği. Maskelenen ikonlarda
  /// (Android/web "maskable") içerik güvenli alana sığsın diye < 1 verilir.
  final double contentScale;

  /// Rozet köşe yarıçapının kenar uzunluğuna oranı.
  static const double cornerRatio = 0.27;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    Offset p(double x, double y) => Offset(x * s, y * s);
    final rect = Offset.zero & Size.square(s);
    final badge = RRect.fromRectAndRadius(rect, Radius.circular(fullBleed ? 0 : s * cornerRatio));

    // 1. Rozet + yumuşak parlama
    canvas.drawRRect(badge, Paint()..shader = EduPulseBrand.badgeGradient.createShader(rect));
    canvas.save();
    canvas.clipRRect(badge);
    final glowCenter = p(0.2, 0.08);
    canvas.drawCircle(
      glowCenter,
      s * 0.7,
      Paint()
        ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.24), Colors.white.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: glowCenter, radius: s * 0.7)),
    );
    canvas.restore();

    if (contentScale != 1.0) {
      canvas.translate(s / 2, s / 2);
      canvas.scale(contentScale);
      canvas.translate(-s / 2, -s / 2);
    }

    // 2. Kep: kalınlık (açık lacivert gölge) + beyaz üst yüzey
    Path board(double dy) => Path()
      ..moveTo(s * 0.5, s * (0.19 + dy))
      ..lineTo(s * 0.83, s * (0.35 + dy))
      ..lineTo(s * 0.5, s * (0.51 + dy))
      ..lineTo(s * 0.17, s * (0.35 + dy))
      ..close();
    canvas.drawPath(board(0.035), Paint()..color = EduPulseBrand.capShade);
    canvas.drawPath(board(0), Paint()..color = Colors.white);

    // 3. Püskül (altın)
    final tassel = Paint()
      ..color = EduPulseBrand.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.5, s * 0.35)
        ..lineTo(s * 0.74, s * 0.395)
        ..lineTo(s * 0.74, s * 0.5),
      tassel,
    );
    canvas.drawCircle(p(0.74, 0.535), s * 0.042, Paint()..color = EduPulseBrand.gold);

    // 4. Nabız çizgisi (tepe noktası kepin alt köşesine uzanır)
    final pulse = Path()
      ..moveTo(s * 0.14, s * 0.71)
      ..lineTo(s * 0.33, s * 0.71)
      ..lineTo(s * 0.40, s * 0.62)
      ..lineTo(s * 0.485, s * 0.85)
      ..lineTo(s * 0.575, s * 0.56)
      ..lineTo(s * 0.645, s * 0.71)
      ..lineTo(s * 0.86, s * 0.71);
    final progress = pulseProgress.clamp(0.0, 1.0);
    if (progress > 0) {
      final drawn = _trim(pulse, progress);
      canvas.drawPath(
        drawn,
        Paint()
          ..color = EduPulseBrand.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.075
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      // Çizim sürerken çizginin ucunda parlayan "nabız" noktası
      if (progress < 1) {
        final head = _pointAt(pulse, progress);
        if (head != null) {
          canvas.drawCircle(
            head,
            s * 0.12,
            Paint()
              ..shader = RadialGradient(
                colors: [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)],
              ).createShader(Rect.fromCircle(center: head, radius: s * 0.12)),
          );
        }
      }
    }

    canvas.restore();
  }

  static Path _trim(Path path, double t) {
    final out = Path();
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * t;
    for (final ui.PathMetric m in metrics) {
      if (remaining <= 0) break;
      final len = remaining.clamp(0.0, m.length);
      out.addPath(m.extractPath(0, len), Offset.zero);
      remaining -= m.length;
    }
    return out;
  }

  static Offset? _pointAt(Path path, double t) {
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var distance = total * t;
    for (final m in metrics) {
      if (distance <= m.length) return m.getTangentForOffset(distance)?.position;
      distance -= m.length;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant EduPulseMarkPainter old) =>
      old.pulseProgress != pulseProgress || old.fullBleed != fullBleed || old.contentScale != contentScale;
}
