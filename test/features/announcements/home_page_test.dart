// Geliştirici 6 — Ana Sayfa (Kampüs Duyuruları + Anlık Kriz Yayını FAB'ı).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/enums/announcement_type.dart';
import 'package:itogram_edupulse/core/enums/user_role.dart';
import 'package:itogram_edupulse/features/announcements/domain/entities/announcement_entity.dart';
import 'package:itogram_edupulse/features/announcements/presentation/pages/home_announcements_page.dart';
import 'package:itogram_edupulse/features/announcements/presentation/widgets/announcement_card.dart';

import '../../helpers/page_harness.dart';

void main() {
  late TestBackend backend;
  setUp(() async {
    backend = TestBackend();
    await backend.register();
    backend.announcements.announcements.items.addAll([
      AnnouncementEntity(
        id: '1',
        title: 'Flutter Hackathon',
        content: '48 saatlik kampüs hackathonu',
        type: AnnouncementType.event,
        eventDate: DateTime.now(),
        authorName: 'Fahri Hoca',
      ),
      const AnnouncementEntity(
        id: '2',
        title: 'Vize Takvimi',
        content: 'Vizeler 20 Kasım\'da başlıyor',
        type: AnnouncementType.exam,
        authorName: 'Öğrenci İşleri',
      ),
    ]);
  });

  testWidgets('duyurular listelenir; öğrenci kriz yayını butonunu görmez (Kural 5)', (tester) async {
    await pumpPage(tester, const HomeAnnouncementsPage(), backend: backend);
    expect(find.byType(AnnouncementCard), findsNWidgets(2));
    expect(find.byKey(const Key('home_broadcast_fab')), findsNothing);
  });

  testWidgets('kategori filtresi listeyi daraltır', (tester) async {
    await pumpPage(tester, const HomeAnnouncementsPage(), backend: backend);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sınav'));
    await settle(tester);
    expect(find.text('Vize Takvimi'), findsOneWidget);
    expect(find.text('Flutter Hackathon'), findsNothing);
  });

  testWidgets('eğitmen "Duyuru / Kriz Yayını" butonunu görür ve seçenekleri açar', (tester) async {
    await pumpPage(tester, const HomeAnnouncementsPage(), backend: backend, role: UserRole.instructor);
    expect(find.byKey(const Key('home_broadcast_fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_broadcast_fab')));
    await settle(tester);
    expect(find.text('Anlık Kriz Yayını (FCM Push)'), findsOneWidget);
    expect(find.text('Takvimli Duyuru Yayınla'), findsOneWidget);
  });

  testWidgets('duyuru yoksa boş durum gösterilir', (tester) async {
    backend.announcements.announcements.items.clear();
    await pumpPage(tester, const HomeAnnouncementsPage(), backend: backend);
    expect(find.text('Duyuru bulunamadı'), findsOneWidget);
  });
}
