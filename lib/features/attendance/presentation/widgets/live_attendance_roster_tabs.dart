import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/attendance_status.dart';

/// Canlı yoklama listesindeki tek öğrenci satırı.
class AttendeeItem {
  const AttendeeItem({
    required this.studentUid,
    required this.studentName,
    required this.studentNo,
    required this.status,
    this.recordedAt,
  });

  final String studentUid;
  final String studentName;
  final String studentNo;
  final AttendanceStatus status;
  final DateTime? recordedAt;
}

/// Yoklama durumu ikonları (Gelen / Geç Kalan / Gelmeyen / İzinli).
IconData attendanceStatusIcon(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => Icons.check_circle_outline_rounded,
  AttendanceStatus.late => Icons.schedule_rounded,
  AttendanceStatus.absent => Icons.cancel_outlined,
  AttendanceStatus.excused => Icons.info_outline_rounded,
};

/// [LiveAttendanceRosterTabs] canlı yoklama listesini sekmelere ayırır:
/// **Gelenler**, **Geç Kalanlar**, **Gelmeyenler** ve **İzinliler**.
/// [onStatusChanged] verilirse (yalnızca eğitmen) her satırda durumu değiştiren menü görünür.
class LiveAttendanceRosterTabs extends StatefulWidget {
  const LiveAttendanceRosterTabs({super.key, required this.attendees, this.onStatusChanged, this.listHeight = 320});

  final List<AttendeeItem> attendees;
  final void Function(AttendeeItem item, AttendanceStatus newStatus)? onStatusChanged;

  /// Sekme içeriğinin yüksekliği (liste kendi içinde kayar).
  final double listHeight;

  @override
  State<LiveAttendanceRosterTabs> createState() => _LiveAttendanceRosterTabsState();
}

class _LiveAttendanceRosterTabsState extends State<LiveAttendanceRosterTabs> with SingleTickerProviderStateMixin {
  static const List<AttendanceStatus> _order = [
    AttendanceStatus.present,
    AttendanceStatus.late,
    AttendanceStatus.absent,
    AttendanceStatus.excused,
  ];

  late final TabController _tabController = TabController(length: _order.length, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = {for (final status in _order) status: widget.attendees.where((a) => a.status == status).toList()};

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
            borderRadius: AppDimensions.radius12,
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: AppDimensions.radius12,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            // Dar ekranda "Gelmeyen (12)" gibi etiketler kırpılmasın diye küçülerek sığar.
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: [
              for (final status in _order)
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${AppStrings.attendanceStatus(status)} (${grouped[status]!.length})', maxLines: 1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.p8),
        SizedBox(
          height: widget.listHeight,
          child: TabBarView(
            controller: _tabController,
            children: [for (final status in _order) _buildList(grouped[status]!, status, isDark)],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<AttendeeItem> items, AttendanceStatus status, bool isDark) {
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    if (items.isEmpty) {
      return Center(
        child: Text('Bu kategoride öğrenci bulunmuyor.', style: TextStyle(color: muted, fontSize: 13)),
      );
    }

    final color = AppColors.forAttendanceStatus(status);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                item.studentName.isNotEmpty ? item.studentName.characters.first.toUpperCase() : 'Ö',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            title: Text(
              item.studentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              item.recordedAt == null ? item.studentNo : '${item.studentNo} • ${_time(item.recordedAt!)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: muted),
            ),
            trailing: widget.onStatusChanged != null
                ? PopupMenuButton<AttendanceStatus>(
                    tooltip: 'Durumu değiştir',
                    icon: Icon(attendanceStatusIcon(status), color: color, size: 20),
                    onSelected: (newStatus) => widget.onStatusChanged!(item, newStatus),
                    itemBuilder: (context) => [
                      for (final s in _order)
                        if (s != status)
                          PopupMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(attendanceStatusIcon(s), size: 18, color: AppColors.forAttendanceStatus(s)),
                                const SizedBox(width: 8),
                                Text('${AppStrings.attendanceStatus(s)} Yap'),
                              ],
                            ),
                          ),
                    ],
                  )
                : Icon(attendanceStatusIcon(status), color: color, size: 20),
          ),
        );
      },
    );
  }

  static String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
