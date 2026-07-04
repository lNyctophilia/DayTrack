/// Tüm UI string'leri — Türkçe ve İngilizce
class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'app_name': {'tr': 'Day Track', 'en': 'Day Track'},

    // Takvim
    'total_days': {'tr': 'Toplam Gün', 'en': 'Total Days'},
    'total_earnings': {'tr': 'Toplam Kazanç', 'en': 'Total Earnings'},

    // Gün isimleri (kısa)
    'mon': {'tr': 'Pzt', 'en': 'Mon'},
    'tue': {'tr': 'Sal', 'en': 'Tue'},
    'wed': {'tr': 'Çar', 'en': 'Wed'},
    'thu': {'tr': 'Per', 'en': 'Thu'},
    'fri': {'tr': 'Cum', 'en': 'Fri'},
    'sat': {'tr': 'Cmt', 'en': 'Sat'},
    'sun': {'tr': 'Paz', 'en': 'Sun'},

    // Ay isimleri
    'january': {'tr': 'Ocak', 'en': 'January'},
    'february': {'tr': 'Şubat', 'en': 'February'},
    'march': {'tr': 'Mart', 'en': 'March'},
    'april': {'tr': 'Nisan', 'en': 'April'},
    'may': {'tr': 'Mayıs', 'en': 'May'},
    'june': {'tr': 'Haziran', 'en': 'June'},
    'july': {'tr': 'Temmuz', 'en': 'July'},
    'august': {'tr': 'Ağustos', 'en': 'August'},
    'september': {'tr': 'Eylül', 'en': 'September'},
    'october': {'tr': 'Ekim', 'en': 'October'},
    'november': {'tr': 'Kasım', 'en': 'November'},
    'december': {'tr': 'Aralık', 'en': 'December'},

    // Form
    'city_inner': {'tr': 'Şehir İçi', 'en': 'In City'},
    'city_outer': {'tr': 'Şehir Dışı', 'en': 'Out of City'},
    'payment': {'tr': 'Ücret', 'en': 'Payment'},
    'note': {'tr': 'Not', 'en': 'Note'},
    'note_hint': {
      'tr': 'Gittiğiniz şehir, detaylar...',
      'en': 'City visited, details...'
    },
    'save': {'tr': 'Kaydet', 'en': 'Save'},
    'delete': {'tr': 'Sil', 'en': 'Delete'},
    'delete_confirm': {
      'tr': 'Bu kaydı silmek istediğinize emin misiniz?',
      'en': 'Are you sure you want to delete this entry?'
    },
    'cancel': {'tr': 'İptal', 'en': 'Cancel'},
    'currency_symbol': {'tr': '₺', 'en': '₺'},

    // Ayarlar
    'settings': {'tr': 'Ayarlar', 'en': 'Settings'},
    'default_payments': {'tr': 'Varsayılan Ücretler', 'en': 'Default Payments'},
    'city_inner_payment': {
      'tr': 'Şehir İçi Ücreti',
      'en': 'In City Payment'
    },
    'city_outer_payment': {
      'tr': 'Şehir Dışı Ücreti',
      'en': 'Out of City Payment'
    },
    'language': {'tr': 'Dil', 'en': 'Language'},
    'turkish': {'tr': 'Türkçe', 'en': 'Türkçe'},
    'english': {'tr': 'English', 'en': 'English'},
    'delete_all_data': {
      'tr': 'Tüm Verileri Sil',
      'en': 'Delete All Data'
    },
    'delete_all_confirm': {
      'tr': 'Tüm iş günü verileriniz silinecek. Bu işlem geri alınamaz!',
      'en': 'All work day data will be deleted. This cannot be undone!'
    },
    'data_deleted': {
      'tr': 'Tüm veriler silindi',
      'en': 'All data deleted'
    },
    'version': {'tr': 'Versiyon', 'en': 'Version'},
    'developer': {'tr': 'Geliştirici', 'en': 'Developer'},
    'all_rights_reserved': {
      'tr': 'Tüm hakları saklıdır',
      'en': 'All rights reserved'
    },
    'about': {'tr': 'Hakkında', 'en': 'About'},
    'general': {'tr': 'Genel', 'en': 'General'},
    'data': {'tr': 'Veri', 'en': 'Data'},
    'saved': {'tr': 'Kaydedildi', 'en': 'Saved'},
    'no_note': {'tr': 'Not yok', 'en': 'No note'},
    'no_entry': {'tr': 'Kayıt yok', 'en': 'No entry'},
  };

  static const List<String> monthKeys = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];

  static const List<String> dayKeys = [
    'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun',
  ];

  static String get(String key, String lang) {
    return _strings[key]?[lang] ?? key;
  }

  static String getMonth(int month, String lang) {
    if (month < 1 || month > 12) return '';
    return get(monthKeys[month - 1], lang);
  }

  static String getDay(int index, String lang) {
    if (index < 0 || index > 6) return '';
    return get(dayKeys[index], lang);
  }
}
