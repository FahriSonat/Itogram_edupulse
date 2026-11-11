import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../cubit/notification_cubit.dart';

/// Üst bardaki zil ikonundan açılan bildirim kutusu.
class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) async {
    final cubit = context.read<NotificationCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(value: cubit, child: const NotificationsSheet()),
    );
    // Kutu kapatıldığında tüm bildirimler okundu sayılır.
    await cubit.markAllRead();
  }

  static IconData _icon(NotificationKind kind) => switch (kind) {
    NotificationKind.crisis => Icons.warning_amber_rounded,
    NotificationKind.announcement => Icons.campaign_rounded,
    NotificationKind.assignment => Icons.assignment_rounded,
    NotificationKind.grade => Icons.grade_rounded,
    NotificationKind.absence => Icons.event_busy_rounded,
    NotificationKind.forum => Icons.forum_rounded,
    NotificationKind.info => Icons.info_outline_rounded,
  };

  static Color _color(NotificationKind kind) => switch (kind) {
    NotificationKind.crisis || NotificationKind.absence => AppColors.criticalAbsenceRed,
    NotificationKind.announcement => AppColors.accentDark,
    NotificationKind.assignment => AppColors.metricPurple,
    NotificationKind.grade => AppColors.resolvedGreen,
    NotificationKind.forum => AppColors.infoBlue,
    NotificationKind.info => AppColors.primaryLight,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.p20, AppDimensions.p20, AppDimensions.p20, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Bildirimler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      if (state.unreadCount > 0)
                        Text('${state.unreadCount} okunmamış', style: TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (state.notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.p32),
                    child: Text(
                      'Henüz bildirimin yok.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: AppDimensions.p16),
                      itemCount: state.notifications.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, i) {
                        final n = state.notifications[i];
                        final unread = state.uid != null && !n.isReadBy(state.uid!);
                        final color = _color(n.kind);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.14),
                            child: Icon(_icon(n.kind), color: color, size: 20),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text('${n.body}\n${DateTimeHelper.relative(n.createdAt)}'),
                          isThreeLine: true,
                          trailing: unread
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.criticalAbsenceRed,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
