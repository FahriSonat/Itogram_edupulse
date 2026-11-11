import 'package:flutter/material.dart';

/// [AppDimensions] provides consistent padding, radius, elevation, and icon size
/// constants across the entire application to ensure a zero-RenderFlex-overflow UI.
abstract final class AppDimensions {
  // ---------------------------------------------------------------------------
  // PADDINGS & MARGINS (Standard Spacings)
  // ---------------------------------------------------------------------------
  static const double p2 = 2.0;
  static const double p4 = 4.0;
  static const double p6 = 6.0;
  static const double p8 = 8.0;
  static const double p10 = 10.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p48 = 48.0;

  // Edge Insets Shortcuts
  static const EdgeInsets paddingZero = EdgeInsets.zero;
  static const EdgeInsets paddingAll4 = EdgeInsets.all(p4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(p8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(p12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(p16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(p20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(p24);

  static const EdgeInsets paddingH16V8 = EdgeInsets.symmetric(horizontal: p16, vertical: p8);
  static const EdgeInsets paddingH16V12 = EdgeInsets.symmetric(horizontal: p16, vertical: p12);
  static const EdgeInsets paddingH20V16 = EdgeInsets.symmetric(horizontal: p20, vertical: p16);
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: p16, vertical: p12);

  // ---------------------------------------------------------------------------
  // BORDER RADIUS (Material 3 Smooth Corners)
  // ---------------------------------------------------------------------------
  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;
  static const double rFull = 999.0;

  // BorderRadius Objects
  static const BorderRadius radius4 = BorderRadius.all(Radius.circular(r4));
  static const BorderRadius radius8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius radius12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius radius16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius radius20 = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius radius24 = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(rFull));

  // ---------------------------------------------------------------------------
  // ICON SIZES
  // ---------------------------------------------------------------------------
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 22.0;
  static const double iconLg = 28.0;
  static const double iconXl = 36.0;
  static const double iconHero = 48.0;

  // ---------------------------------------------------------------------------
  // CARD & BUTTON ELEVATION
  // ---------------------------------------------------------------------------
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationHigh = 4.0;

  // ---------------------------------------------------------------------------
  // COMPONENT HEIGHTS
  // ---------------------------------------------------------------------------
  static const double buttonHeight = 50.0;
  static const double buttonHeightSm = 40.0;
  static const double inputHeight = 52.0;
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 72.0;
  static const double cardMinHeight = 80.0;
  static const double avatarSizeSm = 36.0;
  static const double avatarSizeMd = 48.0;
  static const double avatarSizeLg = 64.0;
}
