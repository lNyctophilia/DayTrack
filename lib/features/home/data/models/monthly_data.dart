import 'work_day.dart';

/// Bir ayın tüm iş günü verisi + hesaplamalar
class MonthlyData {
  final int year;
  final int month;
  final List<WorkDay> workDays;

  const MonthlyData({
    required this.year,
    required this.month,
    required this.workDays,
  });

  int get totalDays => workDays.length;

  double get totalEarnings =>
      workDays.fold(0.0, (sum, day) => sum + day.payment);

  /// Belirli bir günde iş var mı?
  WorkDay? getWorkDay(int day) {
    try {
      return workDays.firstWhere(
        (wd) => wd.date.day == day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Boş ay
  static MonthlyData empty(int year, int month) {
    return MonthlyData(year: year, month: month, workDays: []);
  }
}
