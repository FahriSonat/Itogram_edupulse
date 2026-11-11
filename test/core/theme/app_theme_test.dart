import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/constants/app_colors.dart';
import 'package:itogram_edupulse/core/constants/app_dimensions.dart';
import 'package:itogram_edupulse/core/enums/announcement_type.dart';
import 'package:itogram_edupulse/core/enums/attendance_status.dart';
import 'package:itogram_edupulse/core/enums/letter_grade.dart';
import 'package:itogram_edupulse/core/enums/submission_status.dart';
import 'package:itogram_edupulse/core/services/local_storage_service.dart';
import 'package:itogram_edupulse/core/theme/app_theme.dart';
import 'package:itogram_edupulse/core/theme/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppColors (Geliştirici 2 renk sabitleri)', () {
    test('şartnamedeki iş kuralı renkleri birebir tanımlı', () {
      expect(AppColors.criticalAbsenceRed, const Color(0xFFDC2626));
      expect(AppColors.resolvedGreen, const Color(0xFF16A34A));
      expect(AppColors.lateSubmissionOrange, isA<Color>());
      expect(AppColors.seedColor, const Color(0xFF3730A3), reason: 'Akademik Lacivert / İndigo tohum rengi');
    });

    test('her harf notu (AA, BA, BB, FF) ayrı bir renge sahip', () {
      final colors = {for (final g in LetterGrade.values) AppColors.forLetterGrade(g)};
      expect(colors.length, LetterGrade.values.length);
      expect(AppColors.forLetterGrade(LetterGrade.AA), AppColors.gradeAA);
      expect(AppColors.forLetterGrade(LetterGrade.FF), AppColors.gradeFF);
    });

    test('durum renkleri iş kurallarıyla tutarlı', () {
      expect(AppColors.forAttendanceStatus(AttendanceStatus.absent), AppColors.criticalAbsenceRed);
      expect(AppColors.forAttendanceStatus(AttendanceStatus.present), AppColors.resolvedGreen);
      expect(AppColors.forSubmissionStatus(SubmissionStatus.late), AppColors.lateSubmissionOrange);
      expect(AppColors.forAnnouncementType(AnnouncementType.crisis), AppColors.criticalAbsenceRed);
    });
  });

  group('AppDimensions', () {
    test('şartnamedeki standart boşluk ve köşe değerleri mevcut', () {
      expect([AppDimensions.p8, AppDimensions.p12, AppDimensions.p16, AppDimensions.p24], [8, 12, 16, 24]);
      expect([AppDimensions.r12, AppDimensions.r16], [12, 16]);
    });
  });

  group('AppTheme (Material 3 + ColorScheme.fromSeed)', () {
    for (final (name, theme, brightness) in [
      ('lightTheme', AppTheme.lightTheme, Brightness.light),
      ('darkTheme', AppTheme.darkTheme, Brightness.dark),
    ]) {
      test('$name Material 3 ve doğru parlaklıkta', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
        expect(theme.colorScheme.brightness, brightness);
      });

      test('$name renk şeması Akademik İndigo tohumundan üretilir', () {
        final seeded = ColorScheme.fromSeed(seedColor: AppColors.seedColor, brightness: brightness);
        // Marka rolleri dışındaki tonlar doğrudan tohumdan gelir.
        expect(theme.colorScheme.surfaceContainerLow, seeded.surfaceContainerLow);
        expect(theme.colorScheme.inversePrimary, seeded.inversePrimary);
        // Kritik risk kırmızısı tema hatası rengidir.
        expect(theme.colorScheme.error, AppColors.criticalAbsenceRed);
      });

      test('$name AppBar, Card, InputDecoration ve ElevatedButton stillerini içerir', () {
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(theme.inputDecorationTheme.focusedErrorBorder, isNotNull);
        expect(theme.elevatedButtonTheme.style, isNotNull);
        expect(theme.bottomNavigationBarTheme.type, BottomNavigationBarType.fixed);
      });
    }

    test('açık tema birincil rengi Royal Blue, koyu tema Electric Blue', () {
      expect(AppTheme.lightTheme.colorScheme.primary, AppColors.primaryLight);
      expect(AppTheme.darkTheme.colorScheme.primary, AppColors.primaryDark);
    });
  });

  group('ThemeCubit (LocalStorageService ile kalıcı tema)', () {
    Future<LocalStorageService> storageWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return LocalStorageService(await SharedPreferences.getInstance());
    }

    test('kayıt yoksa açık tema ile başlar', () async {
      final cubit = ThemeCubit(await storageWith({}));
      expect(cubit.state, ThemeMode.light);
      expect(cubit.isDarkMode, isFalse);
      await cubit.close();
    });

    test('kayıtlı koyu tema tercihini senkron olarak yükler (açılışta flash yok)', () async {
      final cubit = ThemeCubit(await storageWith({ThemeCubit.themePrefKey: true}));
      expect(cubit.state, ThemeMode.dark);
      await cubit.close();
    });

    test('toggleTheme modu değiştirir ve LocalStorageService\'e yazar', () async {
      final storage = await storageWith({});
      final cubit = ThemeCubit(storage);

      await cubit.toggleTheme();
      expect(cubit.state, ThemeMode.dark);
      expect(storage.getBool(ThemeCubit.themePrefKey), isTrue);

      await cubit.toggleTheme();
      expect(cubit.state, ThemeMode.light);
      expect(storage.getBool(ThemeCubit.themePrefKey), isFalse);

      // Yeni oturum aynı tercihle açılır.
      await cubit.setTheme(ThemeMode.dark);
      expect(ThemeCubit(storage).state, ThemeMode.dark);
      await cubit.close();
    });

    test('kapatılmış cubit\'e tema yazmak hata fırlatmaz', () async {
      final cubit = ThemeCubit(await storageWith({}));
      await cubit.close();
      await expectLater(cubit.setTheme(ThemeMode.dark), completes);
    });
  });
}
