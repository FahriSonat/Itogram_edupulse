import '../enums/announcement_type.dart';
import '../enums/attendance_status.dart';
import '../enums/submission_status.dart';
import '../enums/user_role.dart';

/// [AppStrings] centralizes all static application titles, menus, validations,
/// and business rule error/warning strings for EduPulse.
abstract final class AppStrings {
  // ---------------------------------------------------------------------------
  // APP BRANDING & IDENTIFIERS
  // ---------------------------------------------------------------------------
  static const String appName = 'EduPulse';
  static const String appTagline = 'Akıllı Kampüs, Hibrit Akademi ve Öğrenci Başarı Ekosistemi';
  static const String appVersion = 'v1.0.0';

  // ---------------------------------------------------------------------------
  // ROLE TITLES & BADGES
  // ---------------------------------------------------------------------------
  static const String studentPortal = 'ÖĞRENCİ PORTALI';
  static const String instructorPortal = 'EĞİTMEN YÖNETİM PANELİ';
  static const String adminPortal = 'YÖNETİCİ PANELİ';
  static const String studentRole = 'Öğrenci / Kursiyer';
  static const String instructorRole = 'Eğitmen / Yönetici';

  // ---------------------------------------------------------------------------
  // GREETINGS & HERO TEXTS
  // ---------------------------------------------------------------------------
  static const String studentGreetingTitle = 'Merhaba, {name}!';
  static const String studentGreetingSubtitle = 'Bugün yeni şeyler öğrenmeye hazır mısın?';
  static const String instructorGreetingTitle = 'Merhaba, {name}!';
  static const String instructorGreetingSubtitle = 'Bugünkü akademik operasyon özeti hazır.';

  // ---------------------------------------------------------------------------
  // NAVIGATION & MENU ITEMS (AppDrawerMenu & BottomNavBar)
  // ---------------------------------------------------------------------------
  static const String navHome = 'Ana Sayfa';
  static const String navSchedule = 'Ders Programı';
  static const String navLiveAttendance = 'Canlı Yoklama';
  static const String navAssignments = 'Ödev Kontrol';
  static const String navAbsence = 'Devamsızlık Kontrol';
  static const String navGrades = 'Not Bilgisi';
  static const String navForum = 'Kampüs Forumu';
  static const String navProfile = 'Profil';
  static const String navThemeToggle = 'Tema Değiştir';
  static const String navLogout = 'Çıkış Yap';

  // Açılır-kapanır menü (AppDrawerMenu) — şartnamedeki 7 ekran bağlantısı
  static const String drawerHome = 'Ana Sayfa (Duyurular)';
  static const String drawerSchedule = 'Ders Programı';
  static const String drawerLiveAttendance = 'Canlı Yoklama';
  static const String drawerAssignments = 'Ödev Kontrol';
  static const String drawerAbsence = 'Devamsızlık Kontrol';
  static const String drawerGrades = 'Not Bilgisi';
  static const String drawerForum = 'Kampüs Forumu';
  static const String themeLight = 'Aydınlık Tema';
  static const String themeDark = 'Karanlık Tema';

  // Kalıcı alt menü (BottomNavigationBar) kısa etiketleri
  static const String tabHome = 'Ana Sayfa';
  static const String tabSchedule = 'Dersler';
  static const String tabAssignments = 'Ödevler';
  static const String tabForum = 'Forum';
  static const String tabGrades = 'Notlar';
  static const String notifications = 'Bildirimler';

  // ---------------------------------------------------------------------------
  // METRICS & DASHBOARD CARDS
  // ---------------------------------------------------------------------------
  static const String nextCourse = 'Sıradaki Ders';
  static const String attendanceRate = 'Ders Katılımı';
  static const String activeAssignments = 'Aktif Ödev';
  static const String gpaTitle = 'Genel GPA';
  static const String courseCompletedBanner = 'Harika ilerliyorsun! Bu hafta 4 dersini tamamladın.';
  static const String startAttendance = 'Yoklamayı Başlat';
  static const String qrPinSubtitle = 'QR / PIN ile anlık yoklama';
  static const String pendingHomeworks = 'Ödevler';
  static const String classAnalysis = 'Sınıf Analizi';
  static const String sendAnnouncement = 'Duyuru Gönder';
  static const String campusQuestions = 'Sorular';
  static const String todaysCourses = 'Bugünkü Derslerim';
  static const String viewAll = 'Tümü';

  // ---------------------------------------------------------------------------
  // KRİTİK İŞ KURALI ETİKETLERİ VE METİNLERİ
  // ---------------------------------------------------------------------------
  // Kural 1: 60 Sn Yoklama Kalkanı
  static const String qrExpirationNotice = 'QR ve 4 haneli PIN kodu 60 saniye geçerlidir.';
  static const String qrExpiredError = 'Yoklama kodunun süresi doldu! Lütfen eğitmenin yeni kodunu bekleyiniz.';
  static const String pinInputLabel = '4 Haneli PIN Kodunu Giriniz';
  static const String scanQrCode = 'Kamera ile QR Okut';

  // Kural 2: Ödev Zaman Kalkanı & Ceza
  static const String lateSubmissionBadge = 'GECİKMİŞ TESLİM (-10 Ceza Puanı)';
  static const String lateSubmissionWarning =
      'Ödev son teslim tarihi geçmiştir. Teslim edebilirsiniz ancak 10 puan gecikme cezası uygulanacaktır.';
  static const String submitAssignment = 'Ödevi Teslim Et';
  static const String deadlineCountdown = 'Son Teslim Tarihine Kalan:';

  // Kural 3: Devamsızlık Uyarı Motoru
  static const String criticalRiskBadge = 'Kritik Risk (%20 Sınırı Aşıldı)';
  static const String criticalRiskNotification =
      'Dersin %20 devamsızlık sınırını aştınız. Lütfen danışmanınızla görüşünüz!';
  static const String absenceSummaryTitle = 'Devamsızlık Durumu';

  // Kural 4: Not Ağırlıklandırma & GPA
  static const String formulaExplanation = 'Başarı Notu = (Vize * 0.40) + (Final * 0.60) + Bonus (Max: 100)';
  static const String midtermLabel = 'Vize Sınavı (%40)';
  static const String finalLabel = 'Final Sınavı (%60)';
  static const String bonusLabel = 'Ödev / Bonus Puan';
  static const String letterGradeAA = 'AA (Mükemmel - 4.0)';
  static const String letterGradeBA = 'BA (Çok İyi - 3.5)';
  static const String letterGradeBB = 'BB (İyi - 3.0)';
  static const String letterGradeFF = 'FF (Başarısız - 0.0)';

  // Kural 5: Mutlak Rol Güvenliği
  static const String unauthorizedAccess = 'Bu alana erişim yetkiniz bulunmamaktadır (Sadece Eğitmen).';

  // ---------------------------------------------------------------------------
  // 4 DURUM KALKANI METİNLERİ (State Views)
  // ---------------------------------------------------------------------------
  static const String loadingMessage = 'Veriler yükleniyor, lütfen bekleyiniz...';
  static const String errorMessage = 'Beklenmeyen bir hata oluştu.';
  static const String retryButton = 'Tekrar Dene';
  static const String emptyListTitle = 'Henüz Veri Bulunamadı';
  static const String emptyListSubtitle = 'Burada görüntülenecek herhangi bir kayıt henüz eklenmemiş.';

  // ---------------------------------------------------------------------------
  // FORM & VALİDASYON UYARILARI
  // ---------------------------------------------------------------------------
  static const String studentNoLabel = 'Öğrenci / Sicil Numarası';
  static const String studentNoRequired = 'Lütfen öğrenci veya sicil numaranızı giriniz.';
  static const String studentNoInvalid = 'Numara yalnızca rakamlardan oluşmalıdır.';
  static const String emailLabel = 'Kurumsal E-Posta Adresi';
  static const String emailRequired = 'E-posta adresi boş bırakılamaz.';
  static const String emailInvalid = 'Lütfen geçerli bir e-posta formatı giriniz.';
  static const String passwordLabel = 'Şifre';
  static const String passwordRequired = 'Şifre alanı zorunludur.';
  static const String passwordTooShort = 'Şifre en az 6 karakter olmalıdır.';
  static const String passwordConfirmLabel = 'Şifre Tekrar';
  static const String passwordsDoNotMatch = 'Girdiğiniz şifreler birbiriyle uyuşmuyor.';
  static const String fullNameLabel = 'Ad Soyad';
  static const String fullNameRequired = 'Ad Soyad alanı boş bırakılamaz.';
  static const String pinCodeLengthError = 'PIN kodu tam 4 haneli rakamlardan oluşmalıdır.';
  static const String scoreRangeError = 'Not girişi 0 ile 100 arasında olmalıdır.';
  static const String fieldRequired = 'Bu alan zorunludur.';
  static const String timeFormatError = 'Saat SS:DD biçiminde olmalıdır (örn: 09:30).';
  static const String endTimeBeforeStart = 'Bitiş saati başlangıçtan sonra olmalıdır.';
  static const String studentSelectionRequired = 'Lütfen sistemden bir öğrenci seçiniz.';

  // ---------------------------------------------------------------------------
  // GERİ SAYIM (CountdownTimerWidget)
  // ---------------------------------------------------------------------------
  static const String countdownExpired = 'Süre Doldu';

  // ---------------------------------------------------------------------------
  // ENUM ETİKETLERİ (Tasarım sistemi tek kaynak — enum dosyasında ek üye gerekmez)
  // ---------------------------------------------------------------------------
  /// Rol rozeti: ÖĞRENCİ PORTALI / EĞİTMEN YÖNETİM PANELİ / YÖNETİCİ PANELİ
  static String portalBadge(UserRole role) => switch (role) {
    UserRole.student => studentPortal,
    UserRole.instructor => instructorPortal,
    UserRole.admin => adminPortal,
  };

  /// Kısa rol adı: Öğrenci / Eğitmen / Yönetici
  static String roleName(UserRole role) => switch (role) {
    UserRole.student => 'Öğrenci',
    UserRole.instructor => 'Eğitmen',
    UserRole.admin => 'Yönetici',
  };

  /// Gelen / Geç Kalan / Gelmeyen / İzinli
  static String attendanceStatus(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => 'Gelen',
    AttendanceStatus.late => 'Geç Kalan',
    AttendanceStatus.absent => 'Gelmeyen',
    AttendanceStatus.excused => 'İzinli',
  };

  /// Bekliyor / Teslim Edildi / Notlandırıldı / Gecikti / Eksik
  static String submissionStatus(SubmissionStatus status) => switch (status) {
    SubmissionStatus.pending => 'Bekliyor',
    SubmissionStatus.submitted => 'Teslim Edildi',
    SubmissionStatus.graded => 'Notlandırıldı',
    SubmissionStatus.late => 'Gecikti',
    SubmissionStatus.missing => 'Eksik',
  };

  /// Genel / Sınav / Ödev / Etkinlik / Acil
  static String announcementType(AnnouncementType type) => switch (type) {
    AnnouncementType.general => 'Genel',
    AnnouncementType.exam => 'Sınav',
    AnnouncementType.assignment => 'Ödev',
    AnnouncementType.event => 'Etkinlik',
    AnnouncementType.urgent => 'Acil',
  };
}
