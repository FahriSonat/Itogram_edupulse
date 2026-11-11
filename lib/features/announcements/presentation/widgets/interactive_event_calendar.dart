import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// [InteractiveEventCalendar] Ana Sayfa'nın üstündeki interaktif etkinlik takvimidir.
///
/// - **Hafta şeridi** (varsayılan): seçili tarihin haftasından başlayan 14 gün;
///   oklarla haftalar arasında gezinilir.
/// - **Ay görünümü**: başlıktaki takvim ikonuyla açılan 7 sütunlu ay ızgarası.
///
/// Etkinliği olan günlerde nokta gösterilir; dokunulan gün [onDateSelected] ile bildirilir.
class InteractiveEventCalendar extends StatefulWidget {
  const InteractiveEventCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.eventDates = const {},
    this.today,
    this.initiallyExpanded = false,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<DateTime> eventDates;

  /// Test ve önizleme için "bugün" değeri (varsayılan: `DateTime.now()`).
  final DateTime? today;

  /// true → ay görünümüyle açılır.
  final bool initiallyExpanded;

  static const List<String> monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  static const List<String> dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const int stripLength = 14;

  @override
  State<InteractiveEventCalendar> createState() => _InteractiveEventCalendarState();
}

class _InteractiveEventCalendarState extends State<InteractiveEventCalendar> {
  late DateTime _weekStart = _mondayOf(widget.selectedDate);
  late DateTime _visibleMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  late bool _monthView = widget.initiallyExpanded;

  DateTime get _today => widget.today ?? DateTime.now();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _mondayOf(DateTime d) => _dateOnly(d).subtract(Duration(days: d.weekday - 1));
  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void didUpdateWidget(covariant InteractiveEventCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      // Seçili gün görünür pencerenin dışına çıktıysa pencere ona kayar.
      final selected = _dateOnly(widget.selectedDate);
      final windowEnd = _weekStart.add(const Duration(days: InteractiveEventCalendar.stripLength));
      if (selected.isBefore(_weekStart) || !selected.isBefore(windowEnd)) {
        _weekStart = _mondayOf(selected);
      }
      _visibleMonth = DateTime(selected.year, selected.month);
    }
  }

  bool _hasEvent(DateTime date) => widget.eventDates.any((e) => _isSameDay(e, date));

  void _shift(int direction) {
    setState(() {
      if (_monthView) {
        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + direction);
      } else {
        _weekStart = _weekStart.add(Duration(days: 7 * direction));
      }
    });
  }

  void _goToToday() {
    setState(() {
      _weekStart = _mondayOf(_today);
      _visibleMonth = DateTime(_today.year, _today.month);
    });
    widget.onDateSelected(_dateOnly(_today));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final labelMonth = _monthView ? _visibleMonth : _weekStart.add(const Duration(days: 3));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppDimensions.p16, right: AppDimensions.p8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Etkinlik Ajandası',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _HeaderIcon(
                icon: Icons.chevron_left_rounded,
                tooltip: _monthView ? 'Önceki ay' : 'Önceki hafta',
                onPressed: () => _shift(-1),
              ),
              Flexible(
                child: TextButton(
                  onPressed: _goToToday,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '${InteractiveEventCalendar.monthNames[labelMonth.month - 1]} ${labelMonth.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                  ),
                ),
              ),
              _HeaderIcon(
                icon: Icons.chevron_right_rounded,
                tooltip: _monthView ? 'Sonraki ay' : 'Sonraki hafta',
                onPressed: () => _shift(1),
              ),
              _HeaderIcon(
                icon: _monthView ? Icons.view_week_rounded : Icons.calendar_month_rounded,
                tooltip: _monthView ? 'Hafta görünümü' : 'Ay görünümü',
                onPressed: () => setState(() => _monthView = !_monthView),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.p8),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _monthView ? _buildMonthGrid(isDark, primary) : _buildWeekStrip(isDark, primary),
        ),
      ],
    );
  }

  Widget _buildWeekStrip(bool isDark, Color primary) {
    final days = List.generate(InteractiveEventCalendar.stripLength, (i) => _weekStart.add(Duration(days: i)));

    return SizedBox(
      height: 74,
      child: ListView.builder(
        key: ValueKey(_weekStart),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p12),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 50,
              child: _DayCell(
                date: date,
                dayLabel: InteractiveEventCalendar.dayNames[date.weekday - 1],
                isSelected: _isSameDay(date, widget.selectedDate),
                isToday: _isSameDay(date, _today),
                hasEvent: _hasEvent(date),
                isDark: isDark,
                primary: primary,
                onTap: () => widget.onDateSelected(date),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthGrid(bool isDark, Color primary) {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leading = first.weekday - 1; // Pazartesi başlangıçlı ızgara
    final cellCount = ((leading + daysInMonth) / 7).ceil() * 7;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p12),
      child: Column(
        children: [
          Row(
            children: [
              for (final d in InteractiveEventCalendar.dayNames)
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.p4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: cellCount,
            itemBuilder: (context, index) {
              final dayNumber = index - leading + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox.shrink();
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
              return _DayCell(
                date: date,
                isSelected: _isSameDay(date, widget.selectedDate),
                isToday: _isSameDay(date, _today),
                hasEvent: _hasEvent(date),
                isDark: isDark,
                primary: primary,
                onTap: () => widget.onDateSelected(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasEvent,
    required this.isDark,
    required this.primary,
    required this.onTap,
    this.dayLabel,
  });

  final DateTime date;
  final String? dayLabel;
  final bool isSelected;
  final bool isToday;
  final bool hasEvent;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final mutedColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${date.day} ${InteractiveEventCalendar.monthNames[date.month - 1]}${hasEvent ? ', etkinlik var' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.radius12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? primary : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: AppDimensions.radius12,
            border: Border.all(
              color: isSelected
                  ? primary
                  : (isToday
                        ? primary.withValues(alpha: 0.5)
                        : (isDark ? AppColors.borderDark : AppColors.borderLight)),
              width: isToday || isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3))]
                : null,
          ),
          // Sabit hücrede büyük yazı ölçeğinde taşmasın diye içerik gerekirse küçülür.
          child: ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dayLabel != null) ...[
                    Text(
                      dayLabel!,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutedColor),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    '${date.day}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasEvent ? (isSelected ? Colors.white : AppColors.accentLight) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
