import 'dart:math' as math;

import 'package:flutter/material.dart';

/// [CampusScene] mockup'taki kampüs illüstrasyonunun vektörel karşılığıdır.
///
/// - Aydınlık tema: krem → gök mavisi gündüz göğü, güneş ışığı, bulutlar,
///   kiremit çatılı saat kuleli kampüs binası ve yeşil tepeler.
/// - Karanlık tema: lacivert gece göğü, yıldızlar, hilal, pencereleri yanan
///   bina ve sokak lambaları.
///
/// Bitmap kullanmadığı için her ekran yoğunluğunda keskin kalır ve tema
/// değiştiğinde anında gündüz/gece sahnesine geçer. Sınırlı (bounded) bir
/// alanda kullanılmalıdır (ör. `SizedBox(height: 140)` veya `Positioned`).
class CampusScene extends StatelessWidget {
  const CampusScene({
    super.key,
    this.isDark,
    this.buildingCenterX = 0.5,
    this.buildingHeight,
    this.groundInset,
    this.showBuilding = true,
    this.fadeTop = false,
    this.borderRadius = BorderRadius.zero,
  });

  /// Null ise aktif temadan okunur.
  final bool? isDark;

  /// Binanın yatay merkezi (0.0 = sol kenar, 1.0 = sağ kenar).
  final double buildingCenterX;

  /// Bina + kule + çatı toplam yüksekliği (px). Null ise alanın %50'si.
  final double? buildingHeight;

  /// Zemin çizgisinin alt kenara uzaklığı (px). Null ise alanın %16'sı.
  final double? groundInset;

  final bool showBuilding;

  /// Üst kenarı şeffaflaştırarak sahneyi ortam arka planıyla kaynaştırır.
  final bool fadeTop;

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;

    Widget scene = CustomPaint(
      size: Size.infinite,
      painter: CampusScenePainter(
        isDark: dark,
        buildingCenterX: buildingCenterX,
        buildingHeight: buildingHeight,
        groundInset: groundInset,
        showBuilding: showBuilding,
      ),
    );

    if (fadeTop) {
      scene = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xFF000000)],
          stops: [0.0, 0.14],
        ).createShader(rect),
        child: scene,
      );
    }

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: ClipRRect(borderRadius: borderRadius, child: scene),
      ),
    );
  }
}

/// Sahnenin tamamını tek geçişte çizen ressam. Durum tutmaz; aynı parametrelerle
/// her zaman aynı görüntüyü üretir (yıldızlar sabit tohumla dağıtılır).
class CampusScenePainter extends CustomPainter {
  CampusScenePainter({
    required this.isDark,
    this.buildingCenterX = 0.5,
    this.buildingHeight,
    this.groundInset,
    this.showBuilding = true,
  });

  final bool isDark;
  final double buildingCenterX;
  final double? buildingHeight;
  final double? groundInset;
  final bool showBuilding;

  // --- Gündüz paleti -----------------------------------------------------------
  static const _daySky = [Color(0xFFFFF8F1), Color(0xFFFFEEDC), Color(0xFFDCEAFF)];
  static const _dayFarHill = Color(0xFFD3EEDC);
  static const _dayNearHill = [Color(0xFFB4E5C6), Color(0xFF94D7AF)];
  static const _dayPath = Color(0xFFF4E6D0);
  static const _dayWall = Color(0xFFF7E4CB);
  static const _dayWallShade = Color(0xFFEBCFA9);
  static const _dayRoof = Color(0xFFD9773F);
  static const _dayTrim = Color(0xFFFFF4E4);
  static const _dayWindow = Color(0xFF9CC4F7);
  static const _dayDoor = Color(0xFF9A6A45);
  static const _dayFoliage = Color(0xFF52C985);
  static const _dayFoliageLight = Color(0xFF8AE3B1);
  static const _dayTrunk = Color(0xFF9A6A45);

  // --- Gece paleti -------------------------------------------------------------
  static const _nightSky = [Color(0xFF0B1220), Color(0xFF101C3B), Color(0xFF1A2C5B)];
  static const _nightFarHill = Color(0xFF15244A);
  static const _nightNearHill = [Color(0xFF12203F), Color(0xFF0C1630)];
  static const _nightPath = Color(0xFF1C2950);
  static const _nightWall = Color(0xFF1F2B4D);
  static const _nightWallShade = Color(0xFF19233F);
  static const _nightRoof = Color(0xFF2E3E6E);
  static const _nightTrim = Color(0xFF2A3961);
  static const _nightWindowOff = Color(0xFF2B3B68);
  static const _windowLit = Color(0xFFFDE68A);
  static const _windowGlow = Color(0xFFFBBF24);
  static const _nightFoliage = Color(0xFF0F3B3A);
  static const _nightFoliageLight = Color(0xFF17534F);
  static const _nightTrunk = Color(0xFF2B2233);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.isFinite) return;

    final w = size.width;
    final h = size.height;
    final groundY = h - (groundInset ?? h * 0.16);
    final totalH = buildingHeight ?? h * 0.5;
    final cx = w * buildingCenterX;
    final bw = totalH * 2.3;

    _paintSky(canvas, Offset.zero & size);

    if (isDark) {
      _paintStars(canvas, size, groundY);
      _paintMoon(canvas, size);
      if (showBuilding) {
        _glow(
          canvas,
          Offset(cx, groundY - totalH * 0.45),
          totalH * 1.7,
          const Color(0xFF3B82F6).withValues(alpha: 0.26),
        );
      }
    } else {
      _paintSun(canvas, size);
      _paintClouds(canvas, size);
    }

    _paintHills(canvas, size, groundY);

    if (showBuilding) {
      _paintWalkway(canvas, size, cx, groundY, bw);
      _paintBuilding(canvas, cx, groundY, totalH, bw);
      if (isDark) _paintLamps(canvas, cx, groundY, totalH, bw);
      _tree(canvas, Offset(cx - bw * 0.6, groundY + 2), totalH * 0.62);
      _tree(canvas, Offset(cx + bw * 0.6, groundY + 2), totalH * 0.54);
    }

    _tree(canvas, Offset(w * 0.05, groundY + h * 0.05), totalH * 0.5);
    _tree(canvas, Offset(w * 0.96, groundY + h * 0.04), totalH * 0.46);
  }

  // ---------------------------------------------------------------------------
  // GÖKYÜZÜ
  // ---------------------------------------------------------------------------
  void _paintSky(Canvas canvas, Rect rect) {
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _nightSky,
            stops: [0.0, 0.55, 1.0],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _daySky,
            stops: [0.0, 0.45, 1.0],
          );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _paintSun(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.86, size.height * 0.12);
    _glow(canvas, c, size.height * 0.6, const Color(0xFFFFE2B0).withValues(alpha: 0.9));
    canvas.drawCircle(
      c,
      (size.height * 0.06).clamp(8.0, 18.0),
      Paint()..color = const Color(0xFFFFD08A).withValues(alpha: 0.85),
    );
  }

  void _paintClouds(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    _cloud(canvas, Offset(w * 0.58, h * 0.13), h * 0.055, paint);
    _cloud(canvas, Offset(w * 0.9, h * 0.46), h * 0.045, paint);
    _cloud(canvas, Offset(w * 0.1, h * 0.58), h * 0.04, paint);
  }

  void _cloud(Canvas canvas, Offset c, double s, Paint paint) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, s * 0.2), width: s * 2.3, height: s * 0.62),
          Radius.circular(s * 0.31),
        ),
      )
      ..addOval(Rect.fromCircle(center: c.translate(-s * 0.48, 0), radius: s * 0.42))
      ..addOval(Rect.fromCircle(center: c.translate(s * 0.12, -s * 0.16), radius: s * 0.56))
      ..addOval(Rect.fromCircle(center: c.translate(s * 0.72, s * 0.06), radius: s * 0.36));
    canvas.drawPath(path, paint);
  }

  void _paintStars(Canvas canvas, Size size, double groundY) {
    final rnd = math.Random(42);
    final count = (size.width * size.height / 2200).clamp(24, 90).toInt();
    final maxY = groundY * 0.8;
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * maxY);
      final r = 0.5 + rnd.nextDouble() * 1.0;
      paint.color = Colors.white.withValues(alpha: 0.3 + rnd.nextDouble() * 0.6);
      canvas.drawCircle(p, r, paint);
    }
    _sparkle(canvas, Offset(size.width * 0.16, size.height * 0.2), 3.4);
    _sparkle(canvas, Offset(size.width * 0.5, size.height * 0.1), 2.6);
    _sparkle(canvas, Offset(size.width * 0.7, size.height * 0.36), 3.0);
  }

  void _sparkle(Canvas canvas, Offset c, double r) {
    _glow(canvas, c, r * 3.2, Colors.white.withValues(alpha: 0.22));
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.92));
  }

  void _paintMoon(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.86, size.height * 0.16);
    final r = (size.height * 0.07).clamp(9.0, 20.0);
    _glow(canvas, c, r * 4.2, const Color(0xFF93C5FD).withValues(alpha: 0.24));
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c.translate(r * 0.5, -r * 0.3), radius: r * 0.86)),
    );
    canvas.drawPath(moon, Paint()..color = const Color(0xFFF1F5FF));
  }

  // ---------------------------------------------------------------------------
  // ZEMİN
  // ---------------------------------------------------------------------------
  void _paintHills(Canvas canvas, Size size, double groundY) {
    final w = size.width;
    final h = size.height;

    final far = Path()
      ..moveTo(0, groundY - h * 0.1)
      ..cubicTo(w * 0.22, groundY - h * 0.2, w * 0.42, groundY - h * 0.02, w * 0.62, groundY - h * 0.1)
      ..cubicTo(w * 0.78, groundY - h * 0.17, w * 0.92, groundY - h * 0.08, w, groundY - h * 0.12)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, Paint()..color = isDark ? _nightFarHill : _dayFarHill);

    final near = Path()
      ..moveTo(0, groundY + h * 0.01)
      ..quadraticBezierTo(w * 0.3, groundY - h * 0.05, w * 0.55, groundY)
      ..quadraticBezierTo(w * 0.8, groundY + h * 0.04, w, groundY - h * 0.03)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final nearRect = Rect.fromLTRB(0, groundY - h * 0.05, w, h);
    canvas.drawPath(
      near,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? _nightNearHill : _dayNearHill,
        ).createShader(nearRect),
    );
  }

  void _paintWalkway(Canvas canvas, Size size, double cx, double groundY, double bw) {
    final path = Path()
      ..moveTo(cx - bw * 0.06, groundY)
      ..lineTo(cx + bw * 0.06, groundY)
      ..lineTo(cx + bw * 0.3, size.height)
      ..lineTo(cx - bw * 0.3, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = (isDark ? _nightPath : _dayPath).withValues(alpha: 0.95));
  }

  // ---------------------------------------------------------------------------
  // KAMPÜS BİNASI (iki kanat + orta blok + saat kulesi)
  // ---------------------------------------------------------------------------
  void _paintBuilding(Canvas canvas, double cx, double groundY, double totalH, double bw) {
    final wall = isDark ? _nightWall : _dayWall;
    final wallShade = isDark ? _nightWallShade : _dayWallShade;
    final roof = isDark ? _nightRoof : _dayRoof;
    final trim = isDark ? _nightTrim : _dayTrim;

    final mainH = totalH * 0.56;
    final spireH = totalH * 0.16;
    final towerH = totalH - mainH - spireH;
    final towerW = bw * 0.16;
    final left = cx - bw / 2;
    final wingW = bw * 0.22;
    final wingH = mainH * 0.8;
    final centerW = bw - wingW * 2;

    // Zemin gölgesi
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY + 2), width: bw * 1.12, height: totalH * 0.09),
      Paint()..color = Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
    );

    final wingL = Rect.fromLTWH(left, groundY - wingH, wingW, wingH);
    final wingR = Rect.fromLTWH(left + wingW + centerW, groundY - wingH, wingW, wingH);
    final center = Rect.fromLTWH(left + wingW, groundY - mainH, centerW, mainH);

    // Kanatlar (sağ kanat gölgede → derinlik)
    canvas.drawRect(wingL, Paint()..color = wall);
    canvas.drawRect(wingR, Paint()..color = wallShade);
    _slopedRoof(canvas, wingL, mainH * 0.2, roof);
    _slopedRoof(canvas, wingR, mainH * 0.2, roof);

    // Orta blok + korniş
    canvas.drawRect(center, Paint()..color = wall);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.left - 2, center.top - mainH * 0.09, center.width + 4, mainH * 0.11),
        const Radius.circular(1.5),
      ),
      Paint()..color = roof,
    );

    // Kaide bandı
    canvas.drawRect(
      Rect.fromLTWH(left, groundY - mainH * 0.08, bw, mainH * 0.08),
      Paint()..color = isDark ? wallShade : _dayWallShade,
    );

    // Pencereler
    final winW = bw * 0.052;
    final winH = mainH * 0.24;
    final doorW = bw * 0.1;
    var seed = 0;
    for (var row = 0; row < 2; row++) {
      final y = center.top + mainH * (0.18 + row * 0.38);
      // Orta blok: kapı ekseninin iki yanında ikişer pencere
      for (final fx in const [0.12, 0.3, 0.7, 0.88]) {
        _window(canvas, Rect.fromLTWH(center.left + centerW * fx - winW / 2, y, winW, winH), seed++);
      }
      // Kanatlar
      for (final wing in [wingL, wingR]) {
        final wy = wing.top + wingH * (0.16 + row * 0.42);
        for (final fx in const [0.3, 0.7]) {
          _window(canvas, Rect.fromLTWH(wing.left + wingW * fx - winW / 2, wy, winW, winH * 0.92), seed++);
        }
      }
    }

    // Kemerli kapı + basamak
    final doorH = mainH * 0.44;
    final doorRect = Rect.fromLTWH(cx - doorW / 2, groundY - doorH, doorW, doorH);
    if (isDark) {
      _glow(canvas, doorRect.center, doorW * 1.4, _windowGlow.withValues(alpha: 0.35));
    }
    canvas.drawRRect(
      RRect.fromRectAndCorners(doorRect, topLeft: Radius.circular(doorW / 2), topRight: Radius.circular(doorW / 2)),
      Paint()..color = isDark ? _windowGlow.withValues(alpha: 0.9) : _dayDoor,
    );
    canvas.drawRect(Rect.fromLTWH(cx - doorW * 0.9, groundY - 2, doorW * 1.8, 3), Paint()..color = trim);

    // Saat kulesi
    final towerRect = Rect.fromLTWH(cx - towerW / 2, center.top - towerH, towerW, towerH + 1);
    canvas.drawRect(towerRect, Paint()..color = isDark ? const Color(0xFF24325A) : _dayWall);
    canvas.drawRect(
      Rect.fromLTWH(towerRect.left - 1.5, towerRect.top - 2, towerRect.width + 3, 3),
      Paint()..color = roof,
    );

    // Sivri çatı + bayrak
    final spireBaseY = towerRect.top - 1;
    final spireTip = Offset(cx, spireBaseY - spireH);
    canvas.drawPath(
      Path()
        ..moveTo(cx - towerW * 0.64, spireBaseY)
        ..lineTo(spireTip.dx, spireTip.dy)
        ..lineTo(cx + towerW * 0.64, spireBaseY)
        ..close(),
      Paint()..color = roof,
    );
    final flagPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final poleTop = spireTip.translate(0, -totalH * 0.09);
    canvas.drawLine(spireTip, poleTop, flagPaint);
    canvas.drawPath(
      Path()
        ..moveTo(poleTop.dx, poleTop.dy)
        ..lineTo(poleTop.dx + totalH * 0.07, poleTop.dy + totalH * 0.022)
        ..lineTo(poleTop.dx, poleTop.dy + totalH * 0.044)
        ..close(),
      Paint()..color = isDark ? const Color(0xFF60A5FA) : const Color(0xFFF97316),
    );

    // Saat kadranı
    final clockC = Offset(cx, towerRect.top + towerH * 0.5);
    final clockR = towerW * 0.3;
    if (isDark) _glow(canvas, clockC, clockR * 3, _windowGlow.withValues(alpha: 0.4));
    canvas.drawCircle(clockC, clockR + 1.2, Paint()..color = trim);
    canvas.drawCircle(clockC, clockR, Paint()..color = isDark ? _windowLit : Colors.white);
    final hand = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = math.max(1.0, clockR * 0.16)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(clockC, clockC.translate(0, -clockR * 0.62), hand);
    canvas.drawLine(clockC, clockC.translate(clockR * 0.45, clockR * 0.1), hand);
  }

  void _slopedRoof(Canvas canvas, Rect block, double height, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(block.left - 2, block.top + 1)
        ..lineTo(block.left + block.width * 0.12, block.top - height)
        ..lineTo(block.right - block.width * 0.12, block.top - height)
        ..lineTo(block.right + 2, block.top + 1)
        ..close(),
      Paint()..color = color,
    );
  }

  void _window(Canvas canvas, Rect rect, int seed) {
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(rect.width / 2),
      topRight: Radius.circular(rect.width / 2),
      bottomLeft: const Radius.circular(1),
      bottomRight: const Radius.circular(1),
    );
    if (!isDark) {
      canvas.drawRRect(rrect.inflate(1.2), Paint()..color = _dayTrim);
      canvas.drawRRect(rrect, Paint()..color = _dayWindow);
      return;
    }
    // Gece: pencerelerin ~%80'i deterministik desenle yanar.
    final lit = (seed * 7 + 3) % 5 != 0;
    if (lit) {
      canvas.drawRRect(
        rrect.inflate(2),
        Paint()
          ..color = _windowGlow.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(rrect, Paint()..color = _windowLit);
    } else {
      canvas.drawRRect(rrect, Paint()..color = _nightWindowOff);
    }
  }

  void _paintLamps(Canvas canvas, double cx, double groundY, double totalH, double bw) {
    final pole = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final dx in [-bw * 0.36, bw * 0.36]) {
      final base = Offset(cx + dx, groundY + totalH * 0.06);
      final top = base.translate(0, -totalH * 0.26);
      canvas.drawLine(base, top, pole);
      _glow(canvas, top, totalH * 0.16, _windowGlow.withValues(alpha: 0.5));
      canvas.drawCircle(top, 2, Paint()..color = _windowLit);
    }
  }

  // ---------------------------------------------------------------------------
  // AĞAÇ
  // ---------------------------------------------------------------------------
  void _tree(Canvas canvas, Offset base, double s) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base.translate(0, -s * 0.2), width: s * 0.12, height: s * 0.42),
        const Radius.circular(2),
      ),
      Paint()..color = isDark ? _nightTrunk : _dayTrunk,
    );
    final foliage = Paint()..color = isDark ? _nightFoliage : _dayFoliage;
    canvas.drawCircle(base.translate(0, -s * 0.62), s * 0.34, foliage);
    canvas.drawCircle(base.translate(-s * 0.22, -s * 0.44), s * 0.26, foliage);
    canvas.drawCircle(base.translate(s * 0.22, -s * 0.44), s * 0.26, foliage);
    canvas.drawCircle(
      base.translate(-s * 0.09, -s * 0.72),
      s * 0.14,
      Paint()..color = (isDark ? _nightFoliageLight : _dayFoliageLight).withValues(alpha: 0.7),
    );
  }

  // ---------------------------------------------------------------------------
  // YARDIMCI
  // ---------------------------------------------------------------------------
  void _glow(Canvas canvas, Offset c, double r, Color color) {
    if (r <= 0) return;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant CampusScenePainter old) {
    return old.isDark != isDark ||
        old.buildingCenterX != buildingCenterX ||
        old.buildingHeight != buildingHeight ||
        old.groundInset != groundInset ||
        old.showBuilding != showBuilding;
  }
}
