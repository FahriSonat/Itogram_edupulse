import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// [AppScrollBehavior] masaüstünde (macOS) fareyle sürükleyerek kaydırmayı açar.
///
/// Flutter varsayılan olarak fare sürüklemesini kaydırma saymaz; bu yüzden
/// macOS'ta yatay listeler (etkinlik takvimi, onboarding PageView) fareyle
/// kaydırılamaz. Dokunmatik, trackpad ve kalem davranışı değişmez.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {...super.dragDevices, PointerDeviceKind.mouse};
}
