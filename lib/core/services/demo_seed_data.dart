import '../constants/firestore_paths.dart';
import '../utils/grade_calculator.dart';

/// [DemoSeedData] ilk açılışta yerel veritabanına yüklenen örnek kampüs verisidir.
///
/// Tarihler yükleme anına ([now]) göre göreli üretilir; böylece ödev geri
/// sayımları ve etkinlik takvimi her kurulumda anlamlı görünür.
/// Tüm demo hesaplarının şifresi: `123456`.
abstract final class DemoSeedData {
  static const String demoPassword = '123456';
  static const String currentTerm = '2026-2027 Güz';
  static const String previousTerm = '2025-2026 Bahar';

  static Map<String, List<Map<String, dynamic>>> build(DateTime now) {
    String iso(DateTime d) => d.toIso8601String();

    // -------------------------------------------------------------------------
    // KULLANICILAR
    // -------------------------------------------------------------------------
    const students = [
      ('u_ayberk', 'Ayberk Erdem', '202604001', 'ayberk.erdem@edupulse.edu.tr'),
      ('u_meltem', 'Meltem Jülide', '202604002', 'meltem.julide@edupulse.edu.tr'),
      ('u_zeynep', 'Zeynep Kaya', '202604003', 'zeynep.kaya@edupulse.edu.tr'),
      ('u_can', 'Can Demir', '202604004', 'can.demir@edupulse.edu.tr'),
      ('u_ahmet', 'Ahmet Eroğlu', '202604005', 'ahmet.eroglu@edupulse.edu.tr'),
      ('u_elif', 'Elif Şahin', '202604006', 'elif.sahin@edupulse.edu.tr'),
    ];

    final users = <Map<String, dynamic>>[
      for (final s in students)
        {
          'id': s.$1,
          'fullName': s.$2,
          'schoolNo': s.$3,
          'email': s.$4,
          'role': 'student',
          'department': 'SoftITO Akademi • Mobil Yazılım',
          'password': demoPassword,
          'createdAt': iso(now),
        },
      {
        'id': 'i_mustafa',
        'fullName': 'Mustafa Hoca',
        'schoolNo': '1001',
        'email': 'mustafa.hoca@edupulse.edu.tr',
        'role': 'instructor',
        'department': 'Eğitmen & Bölüm Koordinatörü',
        'password': demoPassword,
        'createdAt': iso(now),
      },
      {
        'id': 'i_ahmet',
        'fullName': 'Dr. Ahmet Hoca',
        'schoolNo': '1002',
        'email': 'ahmet.hoca@edupulse.edu.tr',
        'role': 'instructor',
        'department': 'Bilgisayar Bilimleri Eğitmeni',
        'password': demoPassword,
        'createdAt': iso(now),
      },
    ];

    // -------------------------------------------------------------------------
    // DERS PROGRAMI (dayOfWeek: 1 = Pazartesi … 5 = Cuma)
    // -------------------------------------------------------------------------
    const courseRows = [
      (
        'c_mob101',
        'MOB101',
        'Flutter ile Mobil Geliştirme',
        'i_mustafa',
        'Mustafa Hoca',
        'A204',
        1,
        '10:30',
        '12:00',
        6,
      ),
      (
        'c_cs201',
        'CS201',
        'Veri Yapıları ve Algoritmalar',
        'i_ahmet',
        'Dr. Ahmet Hoca',
        'B107',
        2,
        '13:00',
        '14:30',
        5,
      ),
      ('c_mob202', 'MOB202', 'Mobil Uygulama Projesi', 'i_mustafa', 'Mustafa Hoca', 'Lab-2', 3, '15:00', '16:30', 4),
      ('c_cld301', 'CLD301', 'Bulut Bilişim ve Firebase', 'i_mustafa', 'Mustafa Hoca', 'A301', 4, '09:00', '10:30', 4),
      ('c_ux210', 'UX210', 'UI/UX Tasarım İlkeleri', 'i_ahmet', 'Dr. Ahmet Hoca', 'D-107', 5, '11:00', '12:30', 3),
      (
        'c_mob101_lab',
        'MOB101',
        'Flutter ile Mobil Geliştirme',
        'i_mustafa',
        'Mustafa Hoca',
        'Lab-1',
        3,
        '10:00',
        '11:30',
        6,
      ),
    ];

    final courses = [
      for (final c in courseRows)
        {
          'id': c.$1,
          'courseCode': c.$2,
          'courseName': c.$3,
          'instructorUid': c.$4,
          'instructorName': c.$5,
          'roomLocation': c.$6,
          'dayOfWeek': c.$7,
          'startTime': c.$8,
          'endTime': c.$9,
          'credit': c.$10,
          'totalHours': 40,
        },
    ];

    // Not ve devamsızlık kayıtları ders koduna göre tekil derslerle tutulur.
    final termCourses = courseRows.where((c) => !c.$1.endsWith('_lab')).toList();

    // -------------------------------------------------------------------------
    // DUYURULAR & ETKİNLİKLER
    // -------------------------------------------------------------------------
    final announcements = [
      {
        'id': 'a_hackathon',
        'title': 'SoftITO Büyük Hackathon 2026',
        'content': 'Mobil ve Bulut odaklı projeleriniz için 48 saatlik maraton başlıyor! Takımını kur ve katıl.',
        'type': 'hackathon',
        'eventDate': iso(DateTime(now.year, now.month, now.day + 4, 10)),
        'authorUid': 'system',
        'authorName': 'Yazılım Akademisi',
        'targetCourse': 'Tüm Kampüs / Genel',
        'createdAt': iso(now.subtract(const Duration(days: 1))),
      },
      {
        'id': 'a_seminar_clean',
        'title': 'Flutter ile Clean Architecture Semineri',
        'content': 'Büyük ölçekli projelerde BLoC, Repository deseni ve katmanlı mimarinin kurumsal uygulanışı.',
        'type': 'seminar',
        'eventDate': iso(DateTime(now.year, now.month, now.day + 7, 14)),
        'authorUid': 'i_mustafa',
        'authorName': 'Mustafa Hoca',
        'targetCourse': 'Flutter ile Mobil Geliştirme',
        'createdAt': iso(now.subtract(const Duration(days: 2))),
      },
      {
        'id': 'a_seminar_ux',
        'title': 'UI/UX Tasarım Atölyesi',
        'content':
            'Figma ile prototipleme, erişilebilirlik ve Material 3 tasarım token\'ları üzerine uygulamalı atölye.',
        'type': 'seminar',
        'eventDate': iso(DateTime(now.year, now.month, now.day + 2, 11)),
        'authorUid': 'i_ahmet',
        'authorName': 'Dr. Ahmet Hoca',
        'targetCourse': 'UI/UX Tasarım İlkeleri',
        'createdAt': iso(now.subtract(const Duration(hours: 20))),
      },
      {
        'id': 'a_holiday',
        'title': 'Dönem Arası Tatili',
        'content': 'Akademik takvim gereği kampüs bu tarihte kapalıdır. Çevrim içi kaynaklar erişime açık kalacaktır.',
        'type': 'holiday',
        'eventDate': iso(DateTime(now.year, now.month, now.day + 12)),
        'authorUid': 'system',
        'authorName': 'Akademi Yönetimi',
        'targetCourse': 'Tüm Kampüs / Genel',
        'createdAt': iso(now.subtract(const Duration(days: 3))),
      },
    ];

    // -------------------------------------------------------------------------
    // ÖDEVLER & TESLİMLER
    // -------------------------------------------------------------------------
    final assignments = [
      {
        'id': 'as_theme',
        'courseName': 'Flutter ile Mobil Geliştirme',
        'title': 'EduPulse UI & Material 3 Tema Teslimi',
        'description': 'Renk paleti, tipografi ve ortak bileşenlerin Material 3 kurallarına göre kodlanması.',
        'rubricCriteria': 'Kod Kalitesi (%40), UI/UX Tasarım (%30), Dokümantasyon (%30)',
        'dueDate': iso(now.add(const Duration(days: 3, hours: 4))),
        'createdByUid': 'i_mustafa',
        'createdByName': 'Mustafa Hoca',
        'createdAt': iso(now.subtract(const Duration(days: 4))),
      },
      {
        'id': 'as_bloc',
        'courseName': 'Veri Yapıları ve Algoritmalar',
        'title': 'BLoC State Management ve 60 Sn Timer',
        'description': 'Yoklama oturumu ve reaktif akışların unit testler ile doğrulanması.',
        'rubricCriteria': 'Doğruluk (%50), Test Kapsamı (%30), Okunabilirlik (%20)',
        'dueDate': iso(now.subtract(const Duration(hours: 2))),
        'createdByUid': 'i_ahmet',
        'createdByName': 'Dr. Ahmet Hoca',
        'createdAt': iso(now.subtract(const Duration(days: 7))),
      },
      {
        'id': 'as_firestore',
        'courseName': 'Bulut Bilişim ve Firebase',
        'title': 'Firestore Veri Modeli Tasarımı',
        'description': 'Kampüs uygulaması için koleksiyon yapısı, güvenlik kuralları ve indeks planı hazırlanması.',
        'rubricCriteria': 'Modelleme (%50), Güvenlik Kuralları (%30), Sunum (%20)',
        'dueDate': iso(now.add(const Duration(days: 6))),
        'createdByUid': 'i_mustafa',
        'createdByName': 'Mustafa Hoca',
        'createdAt': iso(now.subtract(const Duration(days: 1))),
      },
      {
        'id': 'as_graph',
        'courseName': 'Veri Yapıları ve Algoritmalar',
        'title': 'Graf Algoritmaları Raporu',
        'description': 'BFS, DFS ve Dijkstra algoritmalarının karmaşıklık analizi ve örnek uygulamaları.',
        'rubricCriteria': 'Analiz (%50), Kod (%30), Rapor (%20)',
        'dueDate': iso(now.subtract(const Duration(days: 5))),
        'createdByUid': 'i_ahmet',
        'createdByName': 'Dr. Ahmet Hoca',
        'createdAt': iso(now.subtract(const Duration(days: 14))),
      },
    ];

    final submissions = [
      {
        'id': 'sub_graph_ayberk',
        'assignmentId': 'as_graph',
        'studentUid': 'u_ayberk',
        'studentName': 'Ayberk Erdem',
        'studentNo': '202604001',
        'fileName': 'Graf_Algoritmalari_Raporu.pdf',
        'fileSizeBytes': 2457600,
        'submittedAt': iso(now.subtract(const Duration(days: 6))),
        'isLate': false,
        'score': 92.0,
        'writtenFeedback': 'Karmaşıklık analizi çok net, Dijkstra örneği öğretici. Tebrikler!',
        'audioFeedbackUrl': null,
        'gradedAt': iso(now.subtract(const Duration(days: 4))),
      },
      {
        'id': 'sub_graph_ahmet',
        'assignmentId': 'as_graph',
        'studentUid': 'u_ahmet',
        'studentName': 'Ahmet Eroğlu',
        'studentNo': '202604005',
        'fileName': 'graf_rapor_v2.docx',
        'fileSizeBytes': 1048576,
        'submittedAt': iso(now.subtract(const Duration(days: 4, hours: 20))),
        'isLate': true,
        'score': 84.0,
        'writtenFeedback': 'İçerik iyi ancak geç teslim nedeniyle 10 puan ceza uygulandı.',
        'audioFeedbackUrl': null,
        'gradedAt': iso(now.subtract(const Duration(days: 3))),
      },
      {
        'id': 'sub_theme_meltem',
        'assignmentId': 'as_theme',
        'studentUid': 'u_meltem',
        'studentName': 'Meltem Jülide',
        'studentNo': '202604002',
        'fileName': 'EduPulse_Theme_Meltem.zip',
        'fileSizeBytes': 14889779,
        'submittedAt': iso(now.subtract(const Duration(days: 1))),
        'isLate': false,
        'score': null,
        'writtenFeedback': null,
        'audioFeedbackUrl': null,
        'gradedAt': null,
      },
      {
        'id': 'sub_theme_zeynep',
        'assignmentId': 'as_theme',
        'studentUid': 'u_zeynep',
        'studentName': 'Zeynep Kaya',
        'studentNo': '202604003',
        'fileName': 'material3_tema.zip',
        'fileSizeBytes': 9437184,
        'submittedAt': iso(now.subtract(const Duration(hours: 5))),
        'isLate': false,
        'score': null,
        'writtenFeedback': null,
        'audioFeedbackUrl': null,
        'gradedAt': null,
      },
      {
        'id': 'sub_bloc_can',
        'assignmentId': 'as_bloc',
        'studentUid': 'u_can',
        'studentName': 'Can Demir',
        'studentNo': '202604004',
        'fileName': 'bloc_timer_tests.zip',
        'fileSizeBytes': 3145728,
        'submittedAt': iso(now.subtract(const Duration(hours: 1))),
        'isLate': true,
        'score': null,
        'writtenFeedback': null,
        'audioFeedbackUrl': null,
        'gradedAt': null,
      },
    ];

    // -------------------------------------------------------------------------
    // DEVAMSIZLIK (her öğrenci × her ders, dönem toplamı 40 saat)
    // -------------------------------------------------------------------------
    // Sütunlar: MOB101, CS201, MOB202, CLD301, UX210
    const absenceTable = {
      'u_ayberk': [4, 9, 2, 0, 6],
      'u_meltem': [2, 2, 0, 2, 0],
      'u_zeynep': [0, 4, 2, 2, 2],
      'u_can': [6, 4, 4, 2, 8],
      'u_ahmet': [10, 9, 6, 4, 2],
      'u_elif': [2, 0, 0, 0, 4],
    };

    final absenceRecords = <Map<String, dynamic>>[];
    for (final s in students) {
      final hours = absenceTable[s.$1]!;
      for (var i = 0; i < termCourses.length; i++) {
        final c = termCourses[i];
        absenceRecords.add({
          'id': '${s.$1}_${c.$1}',
          'studentUid': s.$1,
          'studentName': s.$2,
          'studentNo': s.$3,
          'courseId': c.$1,
          'courseCode': c.$2,
          'courseName': c.$3,
          'absentHours': hours[i],
          'totalHours': 40,
        });
      }
    }

    // -------------------------------------------------------------------------
    // NOTLAR (vize, final, bonus) — null: henüz not girilmedi
    // -------------------------------------------------------------------------
    const gradeTable = <String, List<(double, double, double)?>>{
      'u_ayberk': [(85, 92, 5), (70, 78, 0), (88, 85, 3), null, (80, 90, 0)],
      'u_meltem': [(90, 95, 2), (82, 80, 0), (75, 88, 0), null, (92, 94, 0)],
      'u_zeynep': [(72, 70, 0), (88, 91, 0), (80, 76, 0), null, (70, 74, 0)],
      'u_can': [(60, 68, 0), (55, 62, 0), (70, 72, 0), null, (65, 70, 5)],
      'u_ahmet': [(45, 58, 0), (50, 61, 0), (62, 66, 0), null, (78, 80, 0)],
      'u_elif': [(95, 98, 0), (77, 85, 0), (90, 92, 0), null, (85, 88, 0)],
    };

    final grades = <Map<String, dynamic>>[];
    Map<String, dynamic> gradeDoc({
      required String id,
      required (String, String, String, String) student,
      String? courseId,
      required String courseCode,
      required String courseName,
      required int credit,
      required String term,
      required (double, double, double) scores,
    }) {
      final total = GradeCalculator.calculateTotal(midterm: scores.$1, finalExam: scores.$2, bonus: scores.$3);
      return {
        'id': id,
        'studentUid': student.$1,
        'studentName': student.$2,
        'studentNo': student.$3,
        'courseId': courseId,
        'courseCode': courseCode,
        'courseName': courseName,
        'credit': credit,
        'term': term,
        'midterm': scores.$1,
        'finalExam': scores.$2,
        'bonus': scores.$3,
        'total': total,
        'letterGrade': GradeCalculator.letterFor(total).name,
        'updatedAt': iso(now.subtract(const Duration(days: 2))),
      };
    }

    for (final s in students) {
      final rows = gradeTable[s.$1]!;
      for (var i = 0; i < termCourses.length; i++) {
        final scores = rows[i];
        if (scores == null) continue;
        final c = termCourses[i];
        grades.add(
          gradeDoc(
            id: 'g_${s.$1}_${c.$1}',
            student: s,
            courseId: c.$1,
            courseCode: c.$2,
            courseName: c.$3,
            credit: c.$10,
            term: currentTerm,
            scores: scores,
          ),
        );
      }
      // Önceki dönem (kümülatif GPA için)
      grades
        ..add(
          gradeDoc(
            id: 'g_${s.$1}_mat101',
            student: s,
            courseCode: 'MAT101',
            courseName: 'Matematik I',
            credit: 6,
            term: previousTerm,
            scores: s.$1 == 'u_ayberk' ? (72, 78, 0) : (80, 84, 0),
          ),
        )
        ..add(
          gradeDoc(
            id: 'g_${s.$1}_prg101',
            student: s,
            courseCode: 'PRG101',
            courseName: 'Programlamaya Giriş',
            credit: 6,
            term: previousTerm,
            scores: s.$1 == 'u_ayberk' ? (90, 95, 0) : (78, 82, 0),
          ),
        );
    }

    // -------------------------------------------------------------------------
    // KAMPÜS FORUMU
    // -------------------------------------------------------------------------
    final forumQuestions = [
      {
        'id': 'q_bellcurve',
        'authorUid': 'u_ayberk',
        'authorName': 'Ayberk Erdem',
        'courseTag': 'Flutter',
        'topicTag': 'CustomPainter',
        'questionText':
            'Sınıf başarı çan eğrisinde Gaussian normal dağılımını Material 3 renkleriyle nasıl en akıcı çizeriz?',
        'photoName': null,
        'createdAt': iso(now.subtract(const Duration(hours: 3))),
        'isResolved': true,
        'resolvedAnswerId': 'ans_bellcurve_mustafa',
      },
      {
        'id': 'q_fcm',
        'authorUid': 'u_meltem',
        'authorName': 'Meltem Jülide',
        'courseTag': 'Firebase',
        'topicTag': 'FCM Push',
        'questionText':
            'Kritik %20 devamsızlık kalkanında topic bazlı bildirim fırlatırken token yenilenmesini nasıl dinliyoruz?',
        'photoName': null,
        'createdAt': iso(now.subtract(const Duration(hours: 6))),
        'isResolved': false,
        'resolvedAnswerId': null,
      },
      {
        'id': 'q_dijkstra',
        'authorUid': 'u_zeynep',
        'authorName': 'Zeynep Kaya',
        'courseTag': 'Algoritmalar',
        'topicTag': 'Graf',
        'questionText': 'Dijkstra algoritması negatif ağırlıklı kenarlarda neden yanlış sonuç veriyor? Bellman-Ford ne zaman tercih edilmeli?',
        'photoName': null,
        'createdAt': iso(now.subtract(const Duration(days: 1, hours: 2))),
        'isResolved': false,
        'resolvedAnswerId': null,
      },
    ];

    final forumAnswers = [
      {
        'id': 'ans_bellcurve_mustafa',
        'questionId': 'q_bellcurve',
        'responderUid': 'i_mustafa',
        'responderName': 'Mustafa Hoca',
        'responderRole': 'instructor',
        'answerText': 'BellCurveChartPainter sınıfında LinearGradient shader ve kesikli çizgi kullanarak harf baremlerini eksene oturtabilirsin.',
        'createdAt': iso(now.subtract(const Duration(hours: 2))),
        'isApproved': true,
      },
      {
        'id': 'ans_bellcurve_meltem',
        'questionId': 'q_bellcurve',
        'responderUid': 'u_meltem',
        'responderName': 'Meltem Jülide',
        'responderRole': 'student',
        'answerText': 'Ben Path.cubicTo ile örnek noktaları birleştirdim, oldukça yumuşak bir eğri çıkıyor.',
        'createdAt': iso(now.subtract(const Duration(hours: 1, minutes: 20))),
        'isApproved': false,
      },
      {
        'id': 'ans_fcm_can',
        'questionId': 'q_fcm',
        'responderUid': 'u_can',
        'responderName': 'Can Demir',
        'responderRole': 'student',
        'answerText':
            'onTokenRefresh akışını dinleyip yeni token\'ı kullanıcı dokümanına yazmak gerekiyor diye biliyorum.',
        'createdAt': iso(now.subtract(const Duration(hours: 4))),
        'isApproved': false,
      },
    ];

    // -------------------------------------------------------------------------
    // BİLDİRİMLER
    // -------------------------------------------------------------------------
    final notifications = [
      {
        'id': 'n_welcome',
        'title': 'EduPulse\'a hoş geldiniz!',
        'body': 'Ders programı, canlı yoklama, ödevler ve notlarınız artık tek uygulamada.',
        'type': 'info',
        'targetUid': null,
        'targetRole': null,
        'createdAt': iso(now.subtract(const Duration(days: 1))),
        'readBy': <String>[],
      },
      {
        'id': 'n_absence_ayberk',
        'title': 'Kritik Devamsızlık Uyarısı',
        'body':
            'Veri Yapıları ve Algoritmalar dersinde %20 devamsızlık sınırını aştınız. Lütfen danışmanınızla görüşünüz!',
        'type': 'absence',
        'targetUid': 'u_ayberk',
        'targetRole': null,
        'createdAt': iso(now.subtract(const Duration(hours: 5))),
        'readBy': <String>[],
      },
    ];

    return {
      FirestorePaths.users: users,
      FirestorePaths.courses: courses,
      FirestorePaths.announcements: announcements,
      FirestorePaths.assignments: assignments,
      FirestorePaths.submissions: submissions,
      FirestorePaths.attendanceSessions: <Map<String, dynamic>>[],
      FirestorePaths.absenceRecords: absenceRecords,
      FirestorePaths.grades: grades,
      FirestorePaths.forumQuestions: forumQuestions,
      FirestorePaths.forumAnswers: forumAnswers,
      FirestorePaths.notifications: notifications,
    };
  }
}
