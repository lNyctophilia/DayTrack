import '../../../../core/services/storage_service.dart';
import '../models/monthly_data.dart';
import '../models/work_day.dart';

/// İş günü verileri için repository — StorageService'i soyutlar
class WorkDayRepository {
  final StorageService _storage;

  WorkDayRepository(this._storage);

  /// Bir ayın verilerini getir
  Future<MonthlyData> getMonthlyData(int year, int month) async {
    final days = await _storage.getMonthWorkDays(year, month);
    return MonthlyData(year: year, month: month, workDays: days);
  }

  /// İş günü kaydet (yeni veya güncelle)
  Future<void> saveWorkDay(WorkDay workDay) async {
    await _storage.saveWorkDay(workDay);
  }

  /// İş günü sil
  Future<void> deleteWorkDay(DateTime date) async {
    await _storage.deleteWorkDay(date);
  }

  /// Tüm verileri sil
  Future<void> deleteAllData() async {
    await _storage.deleteAllData();
  }
}
