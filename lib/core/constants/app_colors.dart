import 'package:flutter/material.dart';

import '../enums/announcement_type.dart';
import '../enums/attendance_status.dart';
import '../enums/letter_grade.dart';
import '../enums/submission_status.dart';

/// [AppColors] defines the complete color palette for EduPulse
/// strictly following the design system and Material 3 specifications.
///
/// Enum → renk eşlemeleri ([forLetterGrade], [forAttendanceStatus] …) yalnızca
/// şartnamede tanımlı enum değerlerine bakar; enum dosyalarında ek bir
/// `color` üyesi bulunmasına ihtiyaç duymaz.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // MATERIAL 3 TOHUM RENGİ (ColorScheme.fromSeed)
  // ---------------------------------------------------------------------------
  /// Akademik Lacivert / İndigo ana tohum rengi. [AppTheme] açık ve koyu
  /// [ColorScheme]'leri bu renkten `ColorScheme.fromSeed` ile üretir.
  static const Color seedColor = Color(0xFF3730A3);

  // ---------------------------------------------------------------------------
  // LIGHT THEME PALETTE (From Design System)
  // ---------------------------------------------------------------------------
  static const Color primaryLight = Color(0xFF2563EB); // Royal Blue
  static const Color primaryLightVariant = Color(0xFF1D4ED8);
  static const Color secondaryLight = Color(0xFF10B981); // Emerald Green
  static const Color accentLight = Color(0xFFF59E0B); // Amber / Warm Orange
  static const Color surfaceLight = Color(0xFFFFFDF9); // Warm off-white
  static const Color backgroundLight = Color(0xFFF6F8FC); // Soft modern zemin
  static const Color cardLight = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color dividerLight = Color(0xFFEEF2F6);

  // ---------------------------------------------------------------------------
  // DARK THEME PALETTE (From Design System)
  // ---------------------------------------------------------------------------
  static const Color primaryDark = Color(0xFF3B82F6); // Electric Blue
  static const Color primaryDarkVariant = Color(0xFF60A5FA);
  static const Color secondaryDark = Color(0xFF14B8A6); // Teal
  static const Color accentDark = Color(0xFF8B5CF6); // Neon Purple
  static const Color surfaceDark = Color(0xFF0F172A); // Slate Dark
  static const Color backgroundDark = Color(0xFF0B1220); // Deep Space Navy
  static const Color cardDark = Color(0xFF11182E); // Dark Navy Card
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B); // Slate 500
  static const Color borderDark = Color(0xFF1E293B); // Slate 800
  static const Color dividerDark = Color(0xFF1E293B);

  // ---------------------------------------------------------------------------
  // KRİTİK İŞ KURALI VE DURUM RENKLERİ (Business Rule Constants)
  // ---------------------------------------------------------------------------
  /// Kritik Devamsızlık Riski Kırmızısı (Kural 3 - %20 Devamsızlık Kalkanı)
  static const Color criticalAbsenceRed = Color(0xFFDC2626);

  /// Çözüldü / Eğitmen Onaylı Cevap Yeşili (Modül 2.6 - Kampüs Forumu)
  static const Color resolvedGreen = Color(0xFF16A34A);

  /// Gecikmiş Teslim Turuncusu (Kural 2 - Ödev Zaman Kalkanı & Ceza)
  static const Color lateSubmissionOrange = Color(0xFFEA580C);

  /// Bilgi & Sistem Bildirim Mavisi
  static const Color infoBlue = Color(0xFF0284C7);

  /// Uyarı / Bekliyor Sarısı
  static const Color warningAmber = Color(0xFFD97706);

  // ---------------------------------------------------------------------------
  // HARF NOTU BAREM RENKLERİ (Kural 4 - Not Ağırlıklandırma Motoru)
  // ---------------------------------------------------------------------------
  static const Color gradeAA = Color(0xFF10B981); // Emerald (4.0)
  static const Color gradeBA = Color(0xFF3B82F6); // Blue (3.5)
  static const Color gradeBB = Color(0xFFF59E0B); // Amber (3.0)
  static const Color gradeFF = Color(0xFFEF4444); // Red (0.0)

  // ---------------------------------------------------------------------------
  // ÇİFT PORTAL ROZET VE VURGU RENKLERİ
  // ---------------------------------------------------------------------------
  /// Öğrenci Portalı Rozet Rengi
  static const Color studentRoleBadge = Color(0xFF2563EB);
  static const Color studentRoleBackground = Color(0xFFDBEAFE);

  /// Eğitmen Yönetim Paneli Rozet Rengi
  static const Color instructorRoleBadge = Color(0xFF7C3AED);
  static const Color instructorRoleBackground = Color(0xFFEDE9FE);

  // ---------------------------------------------------------------------------
  // İSTATİSTİK VE KART GRADYANLARI
  // ---------------------------------------------------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient instructorHeroGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient studentHeroGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF11182E), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient qrCardGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---------------------------------------------------------------------------
  // ATMOSFER (Mockup'taki sahne, ortam ışığı ve vurgu dili)
  // ---------------------------------------------------------------------------
  /// Light temanın "enerji" vurgusu: Sıradaki Ders rozeti, seçili alt menü,
  /// geri sayım okları. Dark temada bu rolü [primaryDark] üstlenir.
  static const Color accentWarm = Color(0xFFF97316);
  static const Color accentWarmSoft = Color(0xFFFFEDD5);

  /// Metrik kartlarının pastel zeminleri (Light).
  static const Color tileGreenLight = Color(0xFFE9F9F0);
  static const Color tilePurpleLight = Color(0xFFF2ECFF);
  static const Color tilePinkLight = Color(0xFFFDEBF4);
  static const Color tileAmberLight = Color(0xFFFFF5E1);
  static const Color tileBlueLight = Color(0xFFE8F0FF);

  /// Metrik ikon renkleri.
  static const Color metricPurple = Color(0xFF8B5CF6);
  static const Color metricPink = Color(0xFFEC4899);

  /// Ortam (ambient) arka planı: sayfanın tepesindeki sıcak ton ve ışık lekeleri.
  static const Color ambientTopLight = Color(0xFFFFF8F1);
  static const Color ambientGlowBlueLight = Color(0xFFDCE8FF);
  static const Color ambientGlowPeachLight = Color(0xFFFFE6D1);
  static const Color ambientGlowBlueDark = Color(0xFF1D4ED8);
  static const Color ambientGlowVioletDark = Color(0xFF7C3AED);

  /// Dark temada kartların etrafındaki mavi hale.
  static const Color glowBlue = Color(0xFF3B82F6);

  /// Alt menü zemini (Dark).
  static const Color navBarDark = Color(0xFF0E1628);

  /// Light temadaki kart gölgesi (Slate 900 tabanlı, çok yumuşak).
  static const Color softShadowLight = Color(0x140F172A);

  /// Sıradaki Ders kartı (Dark) ve Yoklamayı Başlat (Dark) için mavi gradyan.
  static const LinearGradient nextClassDarkGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Yoklamayı Başlat (Light) için indigo → mor gradyan.
  static const LinearGradient attendanceCtaLightGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF7C5CF6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Başarı halkası (%86 Genel Başarı) için yeşil → mavi süpürme.
  static const List<Color> successRingColors = [Color(0xFF10B981), Color(0xFF14B8A6), Color(0xFF3B82F6)];

  // ---------------------------------------------------------------------------
  // ENUM → RENK EŞLEMELERİ (Tasarım sistemi tek kaynak)
  // ---------------------------------------------------------------------------
  /// AA, BA, BB, FF harf notu rozet rengi.
  static Color forLetterGrade(LetterGrade grade) => switch (grade) {
    LetterGrade.AA => gradeAA,
    LetterGrade.BA => gradeBA,
    LetterGrade.BB => gradeBB,
    LetterGrade.FF => gradeFF,
  };

  /// Gelen / Gelmeyen / İzinli yoklama durumu rengi.
  static Color forAttendanceStatus(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => resolvedGreen,
    AttendanceStatus.absent => criticalAbsenceRed,
    AttendanceStatus.excused => warningAmber,
  };

  /// Bekliyor / Teslim Edildi / Gecikti ödev teslim durumu rengi.
  static Color forSubmissionStatus(SubmissionStatus status) => switch (status) {
    SubmissionStatus.pending => warningAmber,
    SubmissionStatus.submitted => resolvedGreen,
    SubmissionStatus.late => lateSubmissionOrange,
  };

  /// Seminer / Hackathon / Resmi Tatil / Anlık Kriz duyuru rozeti rengi.
  static Color forAnnouncementType(AnnouncementType type) => switch (type) {
    AnnouncementType.seminar => primaryLight,
    AnnouncementType.hackathon => accentDark,
    AnnouncementType.holiday => secondaryLight,
    AnnouncementType.crisis => criticalAbsenceRed,
  };
}
