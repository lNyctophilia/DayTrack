import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/monthly_data.dart';
import '../../data/models/work_day.dart';

/// Aylık takvim grid widget'ı
class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final MonthlyData monthlyData;
  final LanguageService lang;
  final void Function(DateTime date, WorkDay? existing) onDayTapped;
  final void Function(DateTime date, WorkDay? existing) onDayLongPressed;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    required this.monthlyData,
    required this.lang,
    required this.onDayTapped,
    required this.onDayLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = AppDateUtils.firstWeekdayOfMonth(year, month);
    final daysInMonth = AppDateUtils.daysInMonth(year, month);
    final rowCount = AppDateUtils.gridRowCount(year, month);

    return Column(
      children: [
        // Gün isimleri başlığı
        _buildDayHeaders(),
        const SizedBox(height: 8),
        // Takvim grid'i
        ...List.generate(rowCount, (row) {
          return _buildWeekRow(row, firstWeekday, daysInMonth);
        }),
      ],
    );
  }

  Widget _buildDayHeaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(7, (i) {
          final isWeekend = i >= 5;
          return Expanded(
            child: Center(
              child: Text(
                lang.dayName(i),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isWeekend
                      ? AppColors.textHint
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWeekRow(int row, int firstWeekday, int daysInMonth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: List.generate(7, (col) {
          final dayIndex = row * 7 + col - firstWeekday + 1;

          if (dayIndex < 1 || dayIndex > daysInMonth) {
            return const Expanded(child: SizedBox(height: 44));
          }

          final date = DateTime(year, month, dayIndex);
          final workDay = monthlyData.getWorkDay(dayIndex);
          final isToday = AppDateUtils.isToday(date);
          final isFuture = date.isAfter(DateTime.now());

          return Expanded(
            child: GestureDetector(
              onTap: () => onDayTapped(date, workDay),
              onLongPress: () => onDayLongPressed(date, workDay),
              child: _DayCell(
                day: dayIndex,
                workDay: workDay,
                isToday: isToday,
                isFuture: isFuture,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final WorkDay? workDay;
  final bool isToday;
  final bool isFuture;

  const _DayCell({
    required this.day,
    this.workDay,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final hasWork = workDay != null;
    final isCityCenter = workDay?.isCityCenter ?? true;

    Color bgColor;
    Color textColor;

    if (hasWork) {
      bgColor = isCityCenter
          ? AppColors.cityInner.withValues(alpha: 0.2)
          : AppColors.cityOuter.withValues(alpha: 0.2);
      textColor = isCityCenter ? AppColors.cityInner : AppColors.cityOuter;
    } else if (isFuture) {
      bgColor = Colors.transparent;
      textColor = AppColors.textHint;
    } else {
      bgColor = Colors.transparent;
      textColor = AppColors.textPrimary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 44,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: AppColors.todayBorder, width: 1.5)
            : hasWork
                ? Border.all(
                    color: isCityCenter
                        ? AppColors.cityInner.withValues(alpha: 0.4)
                        : AppColors.cityOuter.withValues(alpha: 0.4),
                    width: 1,
                  )
                : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasWork || isToday
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: textColor,
              ),
            ),
            if (hasWork)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isCityCenter
                      ? AppColors.cityInner
                      : AppColors.cityOuter,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
