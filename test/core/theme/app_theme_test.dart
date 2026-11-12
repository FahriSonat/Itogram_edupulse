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

    test('tüm harf notları (AA..FF, NA) renk eşlemesine sahip', () {
      for (final g in LetterGrade.values) {
        expect(AppColors.forLetterGrade(g), isA<Color>());
      }
      expect(AppColors.forLetterGrade(LetterGrade.AA), AppColors.gradeAA);
      expect(AppColors.forLetterGrade(LetterGrade.BA), AppColors.gradeBA);
      expect(AppColors.forLetterGrade(LetterGrade.BB), AppColors.gradeBB);
      expect(AppColors.forLetterGrade(LetterGrade.DD), AppColors.gradeDD);
      expect(AppColors.forLetterGrade(LetterGrade.FF), AppColors.gradeFF);
      expect(AppColors.forLetterGrade(LetterGrade.NA), AppColors.gradeNA);
    });

    test('durum renkleri iş kurallarıyla tutarlı', () {
      expect(AppColors.forAttendanceStatus(AttendanceStatus.absent), AppColors.criticalAbsenceRed);
      expect(AppColors.forAttendanceStatus(AttendanceStatus.late), AppColors.lateSubmissionOrange);
      expect(AppColors.forAttendanceStatus(AttendanceStatus.present), AppColors.resolvedGreen);
      expect(AppColors.forSubmissionStatus(SubmissionStatus.late), AppColors.lateSubmissionOrange);
      expect(AppColors.forSubmissionStatus(SubmissionStatus.missing), AppColors.criticalAbsenceRed);
      expect(AppColors.forAnnouncementType(AnnouncementType.urgent), AppColors.criticalAbsenceRed);
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
        expect(theme.colorScheme.surfaceContainerLow, seeded.surfaceContainerLow);
        expect(theme.colorScheme.inversePrimary, seeded.inversePrimary);
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
      await cubit.loadSavedTheme();
      expect(cubit.state, ThemeMode.light);
      expect(cubit.isDarkMode, isFalse);
      await cubit.close();
    });

    test('kayıtlı koyu tema tercihini yükler', () async {
      final cubit = ThemeCubit(await storageWith({LocalStorageService.keyThemeMode: 'dark'}));
      await cubit.loadSavedTheme();
      expect(cubit.state, ThemeMode.dark);
      await cubit.close();
    });

    test('toggleTheme modu değiştirir ve LocalStorageService\'e yazar', () async {
      final storage = await storageWith({});
      final cubit = ThemeCubit(storage);

      await cubit.toggleTheme();
      expect(cubit.state, ThemeMode.dark);
      expect(await storage.getThemeMode(), 'dark');

      await cubit.toggleTheme();
      expect(cubit.state, ThemeMode.light);
      expect(await storage.getThemeMode(), 'light');

      await cubit.setTheme(ThemeMode.dark);
      final restored = ThemeCubit(storage);
      await restored.loadSavedTheme();
      expect(restored.state, ThemeMode.dark);
      await cubit.close();
      await restored.close();
    });

    test('erken setTheme çağrısı asenkron loadSavedTheme tarafından ezilmez', () async {
      final storage = await storageWith({LocalStorageService.keyThemeMode: 'light'});
      final cubit = ThemeCubit(storage);
      await cubit.setTheme(ThemeMode.dark);
      await cubit.loadSavedTheme();
      expect(cubit.state, ThemeMode.dark);
      await cubit.close();
    });

    test('kapatılmış cubit\'e tema yazmak hata fırlatmaz', () async {
      final cubit = ThemeCubit(await storageWith({}));
      await cubit.close();
      await expectLater(cubit.setTheme(ThemeMode.dark), completes);
    });
  });
}

