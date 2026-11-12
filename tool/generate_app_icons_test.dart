// EduPulse logosundan (EduPulseMarkPainter) tüm platform uygulama ikonlarını üretir:
// iOS (RGB, alfa kanalsız), macOS, Android, web ve Windows (.ico).
// Logo değişirse proje kökünde çalıştırın:
//   flutter test tool/generate_app_icons_test.dart
// test/ klasörü dışında olduğu için normal `flutter test` çalıştırmasına dahil değildir.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/widgets/brand/edupulse_mark.dart';

enum IconStyle { fullBleed, rounded, macos, maskable }

Future<ui.Image> _render(int px, IconStyle style) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = px.toDouble();

  switch (style) {
    case IconStyle.fullBleed:
      const EduPulseMarkPainter(fullBleed: true).paint(canvas, Size.square(size));
    case IconStyle.maskable:
      const EduPulseMarkPainter(fullBleed: true, contentScale: 0.8).paint(canvas, Size.square(size));
    case IconStyle.rounded:
      final inset = size * 0.03;
      canvas.translate(inset, inset);
      const EduPulseMarkPainter().paint(canvas, Size.square(size - inset * 2));
    case IconStyle.macos:
      // Apple macOS şablonu: 1024 tuvalde ~824 px rozet + yumuşak gölge
      final content = size * 0.805;
      final inset = (size - content) / 2;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset + size * 0.012, content, content),
        Radius.circular(content * EduPulseMarkPainter.cornerRatio),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.28)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.012),
      );
      canvas.translate(inset, inset);
      const EduPulseMarkPainter().paint(canvas, Size.square(content));
  }
  return recorder.endRecording().toImage(px, px);
}

Future<Uint8List> _pngRgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

/// App Store, alfa kanalı içeren ikonları reddeder → iOS için RGB PNG.
Future<Uint8List> _pngRgb(ui.Image image) async {
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  final w = image.width;
  final h = image.height;
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(0); // filtre: yok
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      raw.add([rgba[i], rgba[i + 1], rgba[i + 2]]);
    }
  }
  final out = BytesBuilder()..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final typeBytes = type.codeUnits;
    out.add(_u32(data.length));
    out.add(typeBytes);
    out.add(data);
    out.add(_u32(_crc32([...typeBytes, ...data])));
  }

  chunk('IHDR', [..._u32(w), ..._u32(h), 8, 2, 0, 0, 0]); // 8 bit, RGB
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.toBytes()));
  chunk('IEND', const []);
  return out.toBytes();
}

List<int> _u32(int v) => [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

/// PNG gömülü Windows .ico dosyası.
Uint8List _ico(List<(int, Uint8List)> images) {
  final header = ByteData(6 + 16 * images.length)
    ..setUint16(0, 0, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, images.length, Endian.little);
  var offset = header.lengthInBytes;
  for (var i = 0; i < images.length; i++) {
    final (px, png) = images[i];
    final e = 6 + i * 16;
    header
      ..setUint8(e, px >= 256 ? 0 : px)
      ..setUint8(e + 1, px >= 256 ? 0 : px)
      ..setUint8(e + 2, 0)
      ..setUint8(e + 3, 0)
      ..setUint16(e + 4, 1, Endian.little)
      ..setUint16(e + 6, 32, Endian.little)
      ..setUint32(e + 8, png.length, Endian.little)
      ..setUint32(e + 12, offset, Endian.little);
    offset += png.length;
  }
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add([for (final (_, png) in images) ...png]))
      .toBytes();
}

void main() {
  test('EduPulse uygulama ikonlarını üret', () async {
    final written = <String>[];
    Future<void> write(String path, int px, IconStyle style, {bool rgb = false}) async {
      final image = await _render(px, style);
      final bytes = rgb ? await _pngRgb(image) : await _pngRgba(image);
      File(path).writeAsBytesSync(bytes);
      written.add('$path ($px px)');
    }

    // iOS — dosya adları/boyutları mevcut AppIcon.appiconset ile birebir
    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final (name, px) in [
      ('Icon-App-20x20@1x', 20), ('Icon-App-20x20@2x', 40), ('Icon-App-20x20@3x', 60),
      ('Icon-App-29x29@1x', 29), ('Icon-App-29x29@2x', 58), ('Icon-App-29x29@3x', 87),
      ('Icon-App-40x40@1x', 40), ('Icon-App-40x40@2x', 80), ('Icon-App-40x40@3x', 120),
      ('Icon-App-60x60@2x', 120), ('Icon-App-60x60@3x', 180),
      ('Icon-App-76x76@1x', 76), ('Icon-App-76x76@2x', 152), ('Icon-App-83.5x83.5@2x', 167),
      ('Icon-App-1024x1024@1x', 1024),
    ]) {
      await write('$ios/$name.png', px, IconStyle.fullBleed, rgb: true);
    }

    // macOS
    const mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final px in [16, 32, 64, 128, 256, 512, 1024]) {
      await write('$mac/app_icon_$px.png', px, IconStyle.macos);
    }

    // Android (legacy launcher)
    for (final (dpi, px) in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]) {
      await write('android/app/src/main/res/mipmap-$dpi/ic_launcher.png', px, IconStyle.rounded);
    }

    // Web
    await write('web/icons/Icon-192.png', 192, IconStyle.rounded);
    await write('web/icons/Icon-512.png', 512, IconStyle.rounded);
    await write('web/icons/Icon-maskable-192.png', 192, IconStyle.maskable);
    await write('web/icons/Icon-maskable-512.png', 512, IconStyle.maskable);
    await write('web/favicon.png', 16, IconStyle.rounded);

    // Windows
    final icoImages = <(int, Uint8List)>[];
    for (final px in [16, 24, 32, 48, 64, 128, 256]) {
      icoImages.add((px, await _pngRgba(await _render(px, IconStyle.rounded))));
    }
    File('windows/runner/resources/app_icon.ico').writeAsBytesSync(_ico(icoImages));
    written.add('windows/runner/resources/app_icon.ico (7 boyut)');


    // ignore: avoid_print
    print(written.join('\n'));
  });
}
