import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/data/models/work_day.dart';

/// JSON dosya + SharedPreferences tabanlı veri depolama servisi
class StorageService {
  static const String _prefsLang = 'language';
  static const String _prefsCityInner = 'city_inner_payment';
  static const String _prefsCityOuter = 'city_outer_payment';
  static const String _prefsLastYear = 'last_viewed_year';
  static const String _prefsLastMonth = 'last_viewed_month';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Dil ──────────────────────────────────────────────────

  String getLanguage() => _prefs.getString(_prefsLang) ?? 'tr';

  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_prefsLang, lang);
  }

  // ─── Varsayılan Ücretler ──────────────────────────────────

  double getCityInnerPayment() =>
      _prefs.getDouble(_prefsCityInner) ?? 1025.0;

  double getCityOuterPayment() =>
      _prefs.getDouble(_prefsCityOuter) ?? 1100.0;

  Future<void> setCityInnerPayment(double value) async {
    await _prefs.setDouble(_prefsCityInner, value);
  }

  Future<void> setCityOuterPayment(double value) async {
    await _prefs.setDouble(_prefsCityOuter, value);
  }

  // ─── Son Görüntülenen Ay ──────────────────────────────────

  int getLastViewedYear() =>
      _prefs.getInt(_prefsLastYear) ?? DateTime.now().year;

  int getLastViewedMonth() =>
      _prefs.getInt(_prefsLastMonth) ?? DateTime.now().month;

  Future<void> setLastViewed(int year, int month) async {
    await _prefs.setInt(_prefsLastYear, year);
    await _prefs.setInt(_prefsLastMonth, month);
  }

  // ─── İş Günü Verisi (JSON dosya) ─────────────────────────

  Future<String> get _dataPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/daytrack_data.json';
  }

  Future<Map<String, dynamic>> _readAllData() async {
    try {
      final file = File(await _dataPath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return json.decode(contents) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  Future<void> _writeAllData(Map<String, dynamic> data) async {
    final file = File(await _dataPath);
    await file.writeAsString(json.encode(data));
  }

  /// Ay anahtarı: "2026-07"
  String _monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  /// Gün anahtarı: "2026-07-04"
  String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Bir ayın tüm iş günlerini getir
  Future<List<WorkDay>> getMonthWorkDays(int year, int month) async {
    final data = await _readAllData();
    final key = _monthKey(year, month);
    final monthData = data[key] as Map<String, dynamic>?;
    if (monthData == null) return [];

    final List<WorkDay> days = [];
    for (final entry in monthData.entries) {
      try {
        days.add(WorkDay.fromJson(entry.value as Map<String, dynamic>));
      } catch (_) {}
    }
    return days;
  }

  /// Tek bir iş gününü kaydet
  Future<void> saveWorkDay(WorkDay workDay) async {
    final data = await _readAllData();
    final monthKey = _monthKey(workDay.date.year, workDay.date.month);
    final dayKey = _dayKey(workDay.date);

    if (data[monthKey] == null) {
      data[monthKey] = <String, dynamic>{};
    }
    (data[monthKey] as Map<String, dynamic>)[dayKey] = workDay.toJson();

    await _writeAllData(data);
  }

  /// Tek bir iş gününü sil
  Future<void> deleteWorkDay(DateTime date) async {
    final data = await _readAllData();
    final monthKey = _monthKey(date.year, date.month);
    final dayKey = _dayKey(date);

    final monthData = data[monthKey] as Map<String, dynamic>?;
    if (monthData != null) {
      monthData.remove(dayKey);
      if (monthData.isEmpty) {
        data.remove(monthKey);
      }
    }

    await _writeAllData(data);
  }

  /// Tüm verileri sil
  Future<void> deleteAllData() async {
    final file = File(await _dataPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
