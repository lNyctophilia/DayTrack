import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import 'storage_service.dart';

/// Dil yönetimi — ChangeNotifier ile reactive
class LanguageService extends ChangeNotifier {
  final StorageService _storage;
  late String _currentLang;

  LanguageService(this._storage) {
    _currentLang = _storage.getLanguage();
  }

  String get currentLang => _currentLang;
  bool get isTurkish => _currentLang == 'tr';

  Future<void> setLanguage(String lang) async {
    if (_currentLang == lang) return;
    _currentLang = lang;
    await _storage.setLanguage(lang);
    notifyListeners();
  }

  /// Kısa erişim: dile göre string döndür
  String tr(String key) => AppStrings.get(key, _currentLang);

  /// Ay ismi
  String monthName(int month) => AppStrings.getMonth(month, _currentLang);

  /// Gün ismi (0=Pzt, 6=Paz)
  String dayName(int index) => AppStrings.getDay(index, _currentLang);
}
