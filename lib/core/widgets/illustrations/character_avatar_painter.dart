import 'package:flutter/material.dart';

/// Avatar karakter tipi.
enum AvatarCharacter { student, instructor }

/// [CharacterAvatarPainter] EduPulse'a özgü, vektörel (düz/flat stil) portre
/// karakterleridir. Görsel dosyası gerektirmez; her boyutta keskin kalır.
///
/// - Öğrenci: mavi kapüşonlu, boynunda turuncu kulaklık, dağınık perçem.
/// - Eğitmen: mor ceket + beyaz gömlek, gözlük, kısa sakal ve bıyık.
///
/// Dairesel bir alana (ClipOval) çizilmek üzere tasarlanmıştır; omuzlar alt
/// kenardan taşar.
class CharacterAvatarPainter extends CustomPainter {
  const CharacterAvatarPainter({required this.character});

  final AvatarCharacter character;

  bool get _isStudent => character == AvatarCharacter.student;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    Offset p(double x, double y) => Offset(x * s, y * s);
    Rect r(double cx, double cy, double w, double h) => Rect.fromCenter(center: p(cx, cy), width: w * s, height: h * s);
    Paint fill(Color c) => Paint()..color = c;
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final skin = _isStudent ? const Color(0xFFF3C9A4) : const Color(0xFFE3AE86);
    final skinShade = _isStudent ? const Color(0xFFE2AF89) : const Color(0xFFCF956B);
    final hair = _isStudent ? const Color(0xFF3B2A21) : const Color(0xFF3D4451);
    final outfit = _isStudent ? const Color(0xFF3B82F6) : const Color(0xFF6D28D9);
    final outfitDark = _isStudent ? const Color(0xFF2563EB) : const Color(0xFF5B21B6);
    const ink = Color(0xFF1F2937);

    // 1. Omuzlar / gövde
    final body = Path()
      ..moveTo(s * 0.06, s * 1.02)
      ..cubicTo(s * 0.08, s * 0.82, s * 0.25, s * 0.73, s * 0.5, s * 0.73)
      ..cubicTo(s * 0.75, s * 0.73, s * 0.92, s * 0.82, s * 0.94, s * 1.02)
      ..close();
    canvas.drawPath(body, fill(outfit));

    // 2. Yaka detayı
    if (_isStudent) {
      // Kapüşon yakası
      canvas.drawOval(r(0.5, 0.76, 0.46, 0.15), fill(outfitDark));
    } else {
      // Beyaz gömlek V yakası + ceket yakaları
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.4, s * 0.73)
          ..lineTo(s * 0.5, s * 0.9)
          ..lineTo(s * 0.6, s * 0.73)
          ..close(),
        fill(Colors.white),
      );
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.37, s * 0.745)
          ..lineTo(s * 0.47, s * 0.93)
          ..lineTo(s * 0.41, s * 0.95)
          ..lineTo(s * 0.31, s * 0.78)
          ..close(),
        fill(outfitDark),
      );
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.63, s * 0.745)
          ..lineTo(s * 0.53, s * 0.93)
          ..lineTo(s * 0.59, s * 0.95)
          ..lineTo(s * 0.69, s * 0.78)
          ..close(),
        fill(outfitDark),
      );
    }

    // 3. Boyun
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.5, 0.68, 0.13, 0.16), Radius.circular(s * 0.04)), fill(skinShade));

    // 4. Saç kütlesi (kafanın arkası)
    if (_isStudent) {
      canvas.drawOval(r(0.5, 0.4, 0.45, 0.46), fill(hair));
    } else {
      canvas.drawOval(r(0.5, 0.43, 0.43, 0.36), fill(hair));
    }

    // 5. Kulaklar + yüz
    canvas.drawCircle(p(0.305, 0.49), s * 0.045, fill(skin));
    canvas.drawCircle(p(0.695, 0.49), s * 0.045, fill(skin));
    canvas.drawOval(r(0.5, 0.48, 0.38, 0.42), fill(skin));

    // 6. Perçem
    if (_isStudent) {
      final fringe = fill(hair);
      canvas.drawCircle(p(0.37, 0.31), s * 0.085, fringe);
      canvas.drawCircle(p(0.47, 0.27), s * 0.1, fringe);
      canvas.drawCircle(p(0.59, 0.28), s * 0.095, fringe);
      canvas.drawCircle(p(0.67, 0.34), s * 0.06, fringe);
      canvas.drawCircle(p(0.55, 0.19), s * 0.07, fringe); // tepe tutamı
    } else {
      // Yandan ayrık kısa saç: alın açık kalır, ayrım çizgisi solda.
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.31, s * 0.44)
          ..quadraticBezierTo(s * 0.3, s * 0.25, s * 0.5, s * 0.245)
          ..quadraticBezierTo(s * 0.7, s * 0.25, s * 0.69, s * 0.43)
          ..quadraticBezierTo(s * 0.67, s * 0.32, s * 0.55, s * 0.3)
          ..quadraticBezierTo(s * 0.44, s * 0.285, s * 0.39, s * 0.32)
          ..quadraticBezierTo(s * 0.34, s * 0.36, s * 0.31, s * 0.44)
          ..close(),
        fill(hair),
      );
      // Hafif kır saç parıltısı
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.47, s * 0.27)
          ..quadraticBezierTo(s * 0.58, s * 0.26, s * 0.65, s * 0.31),
        stroke(const Color(0xFF6B7280).withValues(alpha: 0.7), 0.014),
      );
    }

    // 7. Sakal (eğitmen) — ağzın altında çene hattı
    if (!_isStudent) {
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.315, s * 0.5)
          ..quadraticBezierTo(s * 0.33, s * 0.69, s * 0.5, s * 0.705)
          ..quadraticBezierTo(s * 0.67, s * 0.69, s * 0.685, s * 0.5)
          ..lineTo(s * 0.645, s * 0.53)
          ..quadraticBezierTo(s * 0.62, s * 0.63, s * 0.5, s * 0.635)
          ..quadraticBezierTo(s * 0.38, s * 0.63, s * 0.355, s * 0.53)
          ..close(),
        fill(hair),
      );
    }

    // 8. Kaşlar
    final brow = stroke(hair, 0.02);
    canvas.drawLine(p(0.395, 0.43), p(0.455, 0.42), brow);
    canvas.drawLine(p(0.545, 0.42), p(0.605, 0.43), brow);

    // 9. Gözler (+ parlama)
    for (final x in [0.43, 0.57]) {
      canvas.drawCircle(p(x, 0.475), s * 0.024, fill(ink));
      canvas.drawCircle(p(x + 0.008, 0.468), s * 0.007, fill(Colors.white));
    }

    // 10. Gözlük (eğitmen)
    if (!_isStudent) {
      final frame = stroke(ink, 0.016);
      for (final x in [0.43, 0.57]) {
        canvas.drawRRect(RRect.fromRectAndRadius(r(x, 0.48, 0.115, 0.085), Radius.circular(s * 0.03)), frame);
      }
      canvas.drawLine(p(0.487, 0.475), p(0.513, 0.475), frame);
      canvas.drawLine(p(0.372, 0.47), p(0.325, 0.46), frame);
      canvas.drawLine(p(0.628, 0.47), p(0.675, 0.46), frame);
    }

    // 11. Burun, yanaklar
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.5, s * 0.5)
        ..quadraticBezierTo(s * 0.485, s * 0.54, s * 0.51, s * 0.545),
      stroke(skinShade, 0.016),
    );
    final cheek = fill(const Color(0xFFF87171).withValues(alpha: 0.28));
    canvas.drawCircle(p(0.385, 0.55), s * 0.032, cheek);
    canvas.drawCircle(p(0.615, 0.55), s * 0.032, cheek);

    // 12. Bıyık + gülümseme
    if (!_isStudent) {
      canvas.drawRRect(RRect.fromRectAndRadius(r(0.5, 0.567, 0.12, 0.024), Radius.circular(s * 0.012)), fill(hair));
    }
    canvas.drawArc(
      r(0.5, _isStudent ? 0.565 : 0.578, 0.11, 0.06),
      0.15 * 3.14159,
      0.7 * 3.14159,
      false,
      stroke(const Color(0xFF9A3412), 0.016),
    );

    // 13. Kulaklık (öğrenci) + kapüşon ipleri
    if (_isStudent) {
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.36, s * 0.74)
          ..quadraticBezierTo(s * 0.5, s * 0.83, s * 0.64, s * 0.74),
        stroke(const Color(0xFF111827), 0.03),
      );
      final cup = fill(const Color(0xFFF97316));
      canvas.drawRRect(RRect.fromRectAndRadius(r(0.345, 0.735, 0.07, 0.1), Radius.circular(s * 0.03)), cup);
      canvas.drawRRect(RRect.fromRectAndRadius(r(0.655, 0.735, 0.07, 0.1), Radius.circular(s * 0.03)), cup);
      final string = stroke(Colors.white, 0.014);
      canvas.drawLine(p(0.465, 0.82), p(0.455, 0.92), string);
      canvas.drawLine(p(0.535, 0.82), p(0.545, 0.92), string);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CharacterAvatarPainter old) => old.character != character;
}
