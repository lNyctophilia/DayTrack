import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/monthly_data.dart';
import '../../data/models/work_day.dart';
import '../../data/repositories/work_day_repository.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/day_entry_sheet.dart';
import '../widgets/summary_card.dart';

/// Ana Sayfa — Takvim + Özet
class HomePage extends StatefulWidget {
  final StorageService storage;
  final LanguageService lang;

  const HomePage({
    super.key,
    required this.storage,
    required this.lang,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late WorkDayRepository _repository;
  late int _currentYear;
  late int _currentMonth;
  MonthlyData _monthlyData = MonthlyData.empty(2026, 1);
  bool _isLoading = true;

  // Animasyon kontrolü
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int _slideDirection = 0; // -1: sola, 1: sağa

  @override
  void initState() {
    super.initState();
    _repository = WorkDayRepository(widget.storage);
    _currentYear = widget.storage.getLastViewedYear();
    _currentMonth = widget.storage.getLastViewedMonth();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data =
        await _repository.getMonthlyData(_currentYear, _currentMonth);
    setState(() {
      _monthlyData = data;
      _isLoading = false;
    });
    // Son görüntülenen ayı kaydet
    widget.storage.setLastViewed(_currentYear, _currentMonth);
  }

  /// Animasyonlu ay değiştirme
  Future<void> _animateMonthChange(int direction) async {
    if (_slideController.isAnimating) return;

    _slideDirection = direction;

    // Çıkış animasyonu — mevcut içerik kayarak çıkar
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(direction.toDouble(), 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInCubic,
    ));

    await _slideController.forward();

    // Ay değiştir
    setState(() {
      if (direction == 1) {
        // Önceki ay
        if (_currentMonth == 1) {
          _currentMonth = 12;
          _currentYear--;
        } else {
          _currentMonth--;
        }
      } else {
        // Sonraki ay
        if (_currentMonth == 12) {
          _currentMonth = 1;
          _currentYear++;
        } else {
          _currentMonth++;
        }
      }
    });

    // Veriyi yükle
    await _loadData();

    // Giriş animasyonu — yeni içerik karşı taraftan girer
    _slideController.reset();

    _slideAnimation = Tween<Offset>(
      begin: Offset(-direction.toDouble(), 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _previousMonth() {
    _animateMonthChange(1); // sağa kayar (önceki ay)
  }

  void _nextMonth() {
    _animateMonthChange(-1); // sola kayar (sonraki ay)
  }

  void _openDayEntry(DateTime date, WorkDay? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayEntrySheet(
        date: date,
        existingEntry: existing,
        storage: widget.storage,
        lang: widget.lang,
        onSaved: _loadData,
        onDeleted: _loadData,
      ),
    );
  }

  void _showNotePreview(DateTime date, WorkDay? existing) {
    // Haptik geri bildirim
    HapticFeedback.mediumImpact();

    final hasEntry = existing != null;
    final hasNote = hasEntry && existing.note.trim().isNotEmpty;

    // Tarih formatla
    final dayNames = widget.lang.currentLang == 'tr'
        ? [
            'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
            'Cuma', 'Cumartesi', 'Pazar'
          ]
        : [
            'Monday', 'Tuesday', 'Wednesday', 'Thursday',
            'Friday', 'Saturday', 'Sunday'
          ];
    final dayName = dayNames[date.weekday - 1];
    final monthName = widget.lang.monthName(date.month);
    final formattedDate = '${date.day} $monthName, $dayName';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasNote
                  ? AppColors.accentLight.withValues(alpha: 0.3)
                  : AppColors.textHint.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst başlık
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasNote
                          ? Icons.sticky_note_2_rounded
                          : Icons.event_note_rounded,
                      color: hasNote
                          ? AppColors.accentLight
                          : AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // Kapatma butonu
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textHint,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // İçerik — sola yaslı
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: hasNote
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Konum bilgisi — sola yaslı
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: (existing.isCityCenter
                                        ? AppColors.cityInner
                                        : AppColors.cityOuter)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                existing.isCityCenter
                                    ? widget.lang.tr('city_inner')
                                    : widget.lang.tr('city_outer'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: existing.isCityCenter
                                      ? AppColors.cityInner
                                      : AppColors.cityOuter,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Not metni — sola yaslı
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              existing.note.trim(),
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            hasEntry
                                ? Icons.note_outlined
                                : Icons.event_busy_rounded,
                            color: AppColors.textHint,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasEntry
                                ? widget.lang.tr('no_note')
                                : widget.lang.tr('no_entry'),
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          storage: widget.storage,
          lang: widget.lang,
          onDataDeleted: _loadData,
        ),
      ),
    );
    // Ayarlardan döndüğünde verileri yenile (ücret değişmiş olabilir)
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Üst bar — farklı renk, yuvarlak alt köşeler
          _buildTopBar(),
          // Ay navigasyonu — ortalanmış
          _buildMonthNavigator(),
          const SizedBox(height: 12),
          // Takvim + Özet — sola/sağa kaydırarak ay değiştirme, ekranda ortalanmış
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentLight,
                    ),
                  )
                : GestureDetector(
                    onHorizontalDragEnd: (details) {
                      const threshold = 300.0; // px/s hız eşiği
                      final velocity =
                          details.primaryVelocity ?? 0;
                      if (velocity > threshold) {
                        _previousMonth(); // sağa kaydır → önceki ay
                      } else if (velocity < -threshold) {
                        _nextMonth(); // sola kaydır → sonraki ay
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: SingleChildScrollView(
                        child: AnimatedBuilder(
                          animation: _slideController,
                          builder: (context, child) {
                            return SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CalendarGrid(
                                year: _currentYear,
                                month: _currentMonth,
                                monthlyData: _monthlyData,
                                lang: widget.lang,
                                onDayTapped: _openDayEntry,
                                onDayLongPressed: _showNotePreview,
                              ),
                              const SizedBox(height: 8),
                              // Özet kartı
                              SummaryCard(
                                totalDays: _monthlyData.totalDays,
                                totalEarnings: _monthlyData.totalEarnings,
                                lang: widget.lang,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
          child: Row(
            children: [
              // App ikon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.accentLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              // App isim — ayrı yazılış
              const Text(
                'Day Track',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              // Ayarlar butonu
              IconButton(
                onPressed: _openSettings,
                icon: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sol ok
            IconButton(
              onPressed: _previousMonth,
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
            // Ay ve yıl — ortalanmış
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Bugünün ayına dön
                  setState(() {
                    _currentYear = DateTime.now().year;
                    _currentMonth = DateTime.now().month;
                  });
                  _loadData();
                },
                child: Column(
                  children: [
                    Text(
                      widget.lang.monthName(_currentMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '$_currentYear',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // Sağ ok
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
