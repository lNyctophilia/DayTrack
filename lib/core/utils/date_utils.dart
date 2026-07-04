/// Tarih yardımcı fonksiyonları
class AppDateUtils {
  AppDateUtils._();

  /// Bir ayın gün sayısı
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Ayın ilk gününün haftanın kaçıncı günü olduğu
  /// Pazartesi = 0, Pazar = 6 (takvim grid'i için)
  static int firstWeekdayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday - 1; // DateTime.monday = 1
  }

  /// Takvim grid'inde gösterilecek toplam satır sayısı
  static int gridRowCount(int year, int month) {
    final firstDay = firstWeekdayOfMonth(year, month);
    final totalDays = daysInMonth(year, month);
    return ((firstDay + totalDays) / 7).ceil();
  }

  /// İki tarih aynı gün mü?
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Bugün mü?
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }
}
