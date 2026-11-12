import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/theme/app_theme.dart';

/// Tasarım sistemi bileşenlerini gerçek EduPulse temasıyla, telefon boyutunda
/// ve istenen yazı ölçeğinde çizer. `RenderFlex overflow` gibi yerleşim
/// hataları test sırasında exception olarak yakalanır.
Future<void> pumpDesign(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  Size size = const Size(360, 800),
  double textScale = 1.0,
  bool scrollable = true,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(body: scrollable ? SingleChildScrollView(child: child) : child),
    ),
  );
  await tester.pump();
}

/// Her tema ve zorlu ekran koşulunda (dar ekran + büyük yazı) bileşeni çizip
/// hiçbir yerleşim hatası oluşmadığını doğrular.
Future<void> expectNoLayoutErrors(WidgetTester tester, Widget Function() build, {bool scrollable = true}) async {
  const scenarios = [
    (dark: false, size: Size(360, 800), textScale: 1.0),
    (dark: true, size: Size(360, 800), textScale: 1.0),
    (dark: false, size: Size(320, 640), textScale: 1.3),
    (dark: true, size: Size(320, 640), textScale: 1.3),
  ];
  for (final s in scenarios) {
    // Hataları ayrıntılarıyla (hatalı widget + dosya:satır) toplamak için geçici yakalayıcı.
    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await pumpDesign(tester, build(), dark: s.dark, size: s.size, textScale: s.textScale, scrollable: scrollable);
    } finally {
      FlutterError.onError = original;
    }
    expect(
      errors,
      isEmpty,
      reason:
          'Yerleşim hatası: dark=${s.dark}, size=${s.size}, textScale=${s.textScale}\n'
          '${errors.map((e) => e.toString()).join('\n')}',
    );
  }
}

