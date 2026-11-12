import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/announcement_type.dart';
import '../../../../core/widgets/role_visibility_guard.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views/empty_state_view.dart';
import '../../../../core/widgets/state_views/error_state_view.dart';
import '../../../../core/widgets/state_views/loading_state_view.dart';
import '../../../auth/presentation/auth_context.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../../schedule/presentation/cubit/schedule_cubit.dart';
import '../../domain/entities/announcement_entity.dart';
import '../cubit/announcement_cubit.dart';
import '../cubit/announcement_state.dart';
import '../widgets/announcement_card.dart';
import '../widgets/create_announcement_sheet.dart';
import '../widgets/crisis_broadcast_bottom_sheet.dart';
import '../widgets/interactive_event_calendar.dart';

/// ANA SAYFA: İnteraktif etkinlik takvimi, filtrelenmiş duyurular ve anlık kriz yayını.
/// 
/// - Üst alanda takvim widget'ı ([InteractiveEventCalendar]) yer alır; gün seçilerek duyurular filtrelenebilir.
/// - Kategori filtre çipleri ([_Filters]) ile duyuru türüne göre (Genel, Sınav, Ödev, Etkinlik, Acil) süzme yapılır.
/// - Yalnızca eğitmen rolündeki kullanıcılar "Duyuru / Kriz Yayını" FAB butonunu görür (Kural 5: Rol kalkanı).
class HomeAnnouncementsPage extends StatelessWidget {
  const HomeAnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = GetIt.instance;
    // Duyuru ve ders programı verilerini sağlayan Cubit'leri inject ediyoruz
    return MultiBlocProvider(
      providers: [
        BlocProvider<AnnouncementCubit>(create: (_) => sl<AnnouncementCubit>()..startWatchingAnnouncements()),
        BlocProvider<ScheduleCubit>(create: (_) => sl<ScheduleCubit>()..start()),
      ],
      child: const _HomeView(),
    );
  }
}

/// Ana sayfa gövdesi: Eğitmen aksiyonları, Cubit durum dinleyicisi ve durum görünümleri.
class _HomeView extends StatelessWidget {
  const _HomeView();

  static const String allCampusLabel = 'Tüm Kampüs';

  @override
  Widget build(BuildContext context) {
    final role = context.currentRole;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Yalnızca eğitmenlerin duyuru ve kriz yayını göndermesine izin veren güvenlik widget'ı
      floatingActionButton: RoleVisibilityGuard.onlyInstructor(
        currentRole: role,
        child: FloatingActionButton.extended(
          key: const Key('home_broadcast_fab'),
          onPressed: () => _openInstructorActions(context),
          icon: const Icon(Icons.campaign_rounded),
          label: const Text('Duyuru / Kriz Yayını'),
        ),
      ),
      body: BlocConsumer<AnnouncementCubit, AnnouncementState>(
        // Kriz bildirimi ve hata mesajlarını kullanıcıya SnackBar olarak iletme
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is CrisisPushSentSuccess) {
            messenger.showSnackBar(const SnackBar(content: Text('Anlık kriz yayını gönderildi.')));
          } else if (state is AnnouncementError) {
            messenger.showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        // Kriz yayını arkaplanda gönderilirken ekranın sıfırlanmasını önlemek için build filtresi
        buildWhen: (_, current) => current is! CrisisPushSending && current is! CrisisPushSentSuccess,
        builder: (context, state) {
          return switch (state) {
            AnnouncementInitial() || AnnouncementLoading() => const LoadingStateView(message: 'Duyurular yükleniyor...'),
            AnnouncementError(:final message) => ErrorStateView(
                message: message,
                onRetry: () => context.read<AnnouncementCubit>().startWatchingAnnouncements(),
              ),
            AnnouncementLoaded() => _LoadedView(state: state),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  /// Duyurunun hedef kitlesini oluşturur: "Tüm Kampüs" ve eğitmenin mevcut dersleri.
  static Map<String, String> _targets(BuildContext context) {
    final courses = context.read<ScheduleCubit>().state.courses;
    final seen = <String>{};
    return <String, String>{
      'all': allCampusLabel,
      for (final CourseScheduleEntity c in courses)
        if (seen.add(c.courseId)) c.courseId: '${c.courseCode} · ${c.courseName}',
    };
  }

  /// Eğitmenin seçim yapacağı alt seçenek menüsünü açar (Standart duyuru veya Acil Kriz Push Bildirimi).
  static Future<void> _openInstructorActions(BuildContext context) async {
    final cubit = context.read<AnnouncementCubit>();
    final author = context.readCurrentUser()?.fullName ?? 'Akademi Yönetimi';
    final targets = _targets(context);

    // Seçim menüsü: Takvimli Duyuru mu yoksa Acil Kriz Yayını mı?
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_note_rounded),
              title: const Text('Takvimli Duyuru Yayınla'),
              subtitle: const Text('Seminer, hackathon, sınav, resmi tatil...'),
              onTap: () => Navigator.pop(sheetContext, 'announcement'),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              title: const Text('Anlık Kriz Yayını (FCM Push)'),
              subtitle: const Text('Tek tuşla tüm kampüse veya derse acil bildirim'),
              onTap: () => Navigator.pop(sheetContext, 'crisis'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;

    if (choice == 'announcement') {
      // Normal takvimli duyuru oluşturma formunu aç
      await CreateAnnouncementSheet.show(
        context,
        targets: targets.values.toList(),
        onCreate: ({
          required String title,
          required String content,
          required AnnouncementType type,
          required DateTime eventDate,
          required String targetCourse,
        }) async {
          final targetId = targets.entries.firstWhere((e) => e.value == targetCourse, orElse: () => targets.entries.first).key;
          await cubit.addAnnouncement(AnnouncementEntity(
            id: '',
            title: title,
            content: content,
            type: type,
            eventDate: eventDate,
            targetCourseId: targetId == 'all' ? null : targetId,
            authorName: author,
          ));
        },
      );
    } else {
      // Tek tuşla anlık kriz yayını (FCM Push) gönderme formunu aç
      await CrisisBroadcastBottomSheet.show(
        context,
        targets: targets,
        onBroadcast: ({
          required String targetId,
          required String targetLabel,
          required String title,
          required String message,
        }) =>
            cubit.sendCrisisBroadcast(
          title: title,
          message: message,
          targetCourseId: targetId == 'all' ? null : targetId,
        ),
      );
    }
  }
}

/// Duyuruların başarıyla yüklendiği ana liste ve takvim görünümü.
class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final AnnouncementLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AnnouncementCubit>();

    // Ders kodları eşlemesi (örn: CS101)
    final courseLabels = <String, String>{
      for (final c in context.watch<ScheduleCubit>().state.courses) c.courseId: c.courseCode,
    };

    // Takvimde nokta ile işaretlenecek etkinlik tarihleri kümesi
    final eventDates = <DateTime>{
      for (final a in state.allAnnouncements)
        if (a.eventDate != null) DateTime(a.eventDate!.year, a.eventDate!.month, a.eventDate!.day),
    };
    final list = state.filteredAnnouncements;

    return RefreshIndicator(
      // Aşağı çekerek yenileme mekanizması
      onRefresh: () async => cubit.startWatchingAnnouncements(),
      child: CustomScrollView(
        slivers: [
          // İnteraktif Etkinlik Takvimi
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.p16, AppDimensions.p12, AppDimensions.p16, 0),
              child: InteractiveEventCalendar(
                selectedDate: state.selectedDate ?? DateTime.now(),
                eventDates: eventDates,
                onDateSelected: cubit.filterByDate,
              ),
            ),
          ),

          // Tür Filtre Çipleri (Genel, Sınav, Ödev, Etkinlik vb.)
          SliverToBoxAdapter(child: _Filters(state: state)),

          // Bölüm Başlığı ve Filtre Sıfırlama Aksiyonu
          SliverToBoxAdapter(
            child: SectionHeader(
              title: state.selectedDate == null ? 'Kampüs Duyuruları' : 'Seçili Günün Duyuruları',
              actionLabel: state.selectedDate == null ? null : 'Tüm Günler',
              onAction: () => cubit.filterByDate(null),
            ),
          ),

          // Filtreye uygun duyuru yoksa gösterilen boş durum görünümü
          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                title: 'Duyuru bulunamadı',
                message: 'Seçili gün veya kategori için duyuru yok.',
                icon: Icons.event_busy_rounded,
              ),
            )
          else
            // Duyuru Kartları Listesi
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.p16, 0, AppDimensions.p16, 96),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.p12),
                itemBuilder: (context, i) {
                  final a = list[i];
                  return AnnouncementCard(
                    title: a.title,
                    content: a.content,
                    type: a.type,
                    eventDate: a.eventDate ?? DateTime.now(),
                    authorName: a.authorName,
                    targetLabel: a.targetCourseId == null ? _HomeView.allCampusLabel : courseLabels[a.targetCourseId],
                    // Takvime ekleme geri bildirimi
                    onAddToCalendar: a.type == AnnouncementType.urgent
                        ? null
                        : () {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(content: Text('"${a.title}" takvime eklendi.')),
                              );
                          },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Duyuru türüne göre (Genel, Sınav, Ödev vb.) yatay kaydırılabilir filtre çipleri.
class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final AnnouncementLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AnnouncementCubit>();
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppDimensions.paddingH16V8,
        children: [
          // "Tümü" filtresi seçeneği
          ChoiceChip(
            label: const Text('Tümü'),
            selected: state.selectedType == null,
            onSelected: (_) => cubit.filterByType(null),
          ),
          // Enum değerlerinden türetilen kategori filtreleri
          for (final type in AnnouncementType.values) ...[
            const SizedBox(width: AppDimensions.p8),
            ChoiceChip(
              label: Text(AppStrings.announcementType(type)),
              selected: state.selectedType == type,
              onSelected: (_) => cubit.filterByType(state.selectedType == type ? null : type),
            ),
          ],
        ],
      ),
    );
  }
}
