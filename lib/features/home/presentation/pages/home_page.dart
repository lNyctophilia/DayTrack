import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  // Manuel animasyon kontrolü (sistem ayarından bağımsız)
  AnimationController? _slideController;
  late Animation<Offset> _inSlideAnimation;
  late Animation<Offset> _outSlideAnimation;
  late Animation<double> _inFadeAnimation;
  late Animation<double> _outFadeAnimation;

  // Önceki ay verileri (çıkış animasyonu için)
  int? _prevYear;
  int? _prevMonth;
  MonthlyData? _prevMonthlyData;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _repository = WorkDayRepository(widget.storage);
    _currentYear = widget.storage.getLastViewedYear();
    _currentMonth = widget.storage.getLastViewedMonth();
    _loadData();
  }

  @override
  void dispose() {
    _slideController?.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final data =
        await _repository.getMonthlyData(_currentYear, _currentMonth);
    setState(() {
      _monthlyData = data;
      _isLoading = false;
    });
    // Son görüntülenen ayı kaydet
    widget.storage.setLastViewed(_currentYear, _currentMonth);
  }

  /// Animasyonlu ay değiştirme — sistem animasyon ayarını yok sayar
  void _changeMonth(int direction) {
    if (_isAnimating) return;

    // Önceki ay verilerini sakla
    _prevYear = _currentYear;
    _prevMonth = _currentMonth;
    _prevMonthlyData = _monthlyData;

    // Yeni ayı hesapla
    if (direction == 1) {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    } else {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    }

    // Sistem animasyon ölçeğini geçici olarak 1.0 yap
    final originalTimeDilation = timeDilation;
    timeDilation = 1.0;

    _slideController?.dispose();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Giren widget: karşı taraftan gelir
    _inSlideAnimation = Tween<Offset>(
      begin: Offset(-direction.toDouble(), 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeOutCubic,
    ));

    // Çıkan widget: aynı yöne gider
    _outSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(direction.toDouble(), 0),
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeInCubic,
    ));

    _inFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController!, curve: Curves.easeOut),
    );

    _outFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController!, curve: Curves.easeIn),
    );

    setState(() => _isAnimating = true);

    _loadData(silent: true);

    _slideController!.forward().then((_) {
      // Sistem ayarını geri yükle
      timeDilation = originalTimeDilation;
      setState(() {
        _isAnimating = false;
        _prevMonthlyData = null;
        _prevYear = null;
        _prevMonth = null;
      });
    });
  }

  void _previousMonth() {
    _changeMonth(1);
  }

  void _nextMonth() {
    _changeMonth(-1);
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Arkaplan Deseni (Tam Ekran, Daha Saydam)
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPatternPainter(
                color: AppColors.textHint.withValues(alpha: 0.04),
              ),
            ),
          ),
          Column(
            children: [
              // Üst bar — farklı renk, yuvarlak alt köşeler
              _buildTopBar(),
              // Takvim + Ay navigasyonu + Özet — kaydırılabilir, ortalanmış
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentLight,
                        ),
                      )
                    : GestureDetector(
                        onHorizontalDragEnd: (details) {
                          const threshold = 300.0;
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity > threshold) {
                            _previousMonth();
                          } else if (velocity < -threshold) {
                            _nextMonth();
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: SingleChildScrollView(
                            child: _isAnimating
                                ? _buildAnimatedContent()
                                : _buildStaticContent(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Animasyon yokken statik içerik
  Widget _buildStaticContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGreeting(_monthlyData),
        _buildMonthNavigator(_currentYear, _currentMonth),
        const SizedBox(height: 16),
        CalendarGrid(
          year: _currentYear,
          month: _currentMonth,
          monthlyData: _monthlyData,
          lang: widget.lang,
          onDayTapped: _openDayEntry,
          onDayLongPressed: _showNotePreview,
        ),
        const SizedBox(height: 15),
        _buildMiniChart(_monthlyData),
        SummaryCard(
          totalDays: _monthlyData.totalDays,
          totalEarnings: _monthlyData.totalEarnings,
          lang: widget.lang,
        ),
        _buildRecentNotes(_monthlyData),
      ],
    );
  }

  /// Animasyon sırasında iki katman üst üste
  Widget _buildAnimatedContent() {
    return Stack(
      children: [
        // Çıkan (eski) içerik
        if (_prevMonthlyData != null)
          SlideTransition(
            position: _outSlideAnimation,
            child: FadeTransition(
              opacity: _outFadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(_prevMonthlyData!),
                  _buildMonthNavigator(_prevYear!, _prevMonth!),
                  const SizedBox(height: 16),
                  CalendarGrid(
                    year: _prevYear!,
                    month: _prevMonth!,
                    monthlyData: _prevMonthlyData!,
                    lang: widget.lang,
                    onDayTapped: _openDayEntry,
                    onDayLongPressed: _showNotePreview,
                  ),
                  const SizedBox(height: 15),
                  _buildMiniChart(_prevMonthlyData!),
                  SummaryCard(
                    totalDays: _prevMonthlyData!.totalDays,
                    totalEarnings: _prevMonthlyData!.totalEarnings,
                    lang: widget.lang,
                  ),
                  _buildRecentNotes(_prevMonthlyData!),
                ],
              ),
            ),
          ),
        // Giren (yeni) içerik
        SlideTransition(
          position: _inSlideAnimation,
          child: FadeTransition(
            opacity: _inFadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(_monthlyData),
                _buildMonthNavigator(_currentYear, _currentMonth),
                const SizedBox(height: 16),
                CalendarGrid(
                  year: _currentYear,
                  month: _currentMonth,
                  monthlyData: _monthlyData,
                  lang: widget.lang,
                  onDayTapped: _openDayEntry,
                  onDayLongPressed: _showNotePreview,
                ),
                const SizedBox(height: 15),
                _buildMiniChart(_monthlyData),
                SummaryCard(
                  totalDays: _monthlyData.totalDays,
                  totalEarnings: _monthlyData.totalEarnings,
                  lang: widget.lang,
                ),
                _buildRecentNotes(_monthlyData),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildMonthNavigator(int year, int month) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                      widget.lang.monthName(month),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '$year',
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

  Widget _buildGreeting(MonthlyData data) {
    final isTr = widget.lang.currentLang == 'tr';
    final greeting = isTr ? 'Merhaba,' : 'Hello,';
    final motivation = data.totalDays > 0
        ? (isTr
            ? 'Bu ay ${data.totalDays} gün çalıştın, harika gidiyorsun!'
            : 'You worked ${data.totalDays} days this month, keep it up!')
        : (isTr
            ? 'Bu ay için henüz kayıt girmedin. Hadi başlayalım!'
            : 'No entries for this month yet. Let\'s start!');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            motivation,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(MonthlyData data) {
    if (data.totalDays == 0) return const SizedBox.shrink();

    final daysInMonth = DateUtils.getDaysInMonth(data.year, data.month);
    
    List<double> intensities = [];
    double currentIntensity = 0.0;
    double maxIntensity = 1.0; 

    for (int i = 1; i <= daysInMonth; i++) {
      final hasWork = data.getWorkDay(i) != null;
      if (hasWork) {
        currentIntensity += 1.0; // Gittikçe yoğunluk artar (tepe oluşur)
      } else {
        // İşe gitmedikçe yoğunluk azalır, birkaç gün sonra 0'a iner
        currentIntensity = (currentIntensity - 0.75).clamp(0.0, double.infinity);
      }
      intensities.add(currentIntensity);
      if (currentIntensity > maxIntensity) {
        maxIntensity = currentIntensity;
      }
    }

    final isTr = widget.lang.currentLang == 'tr';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTr ? 'Aylık İş Yoğunluğu' : 'Monthly Work Intensity',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(Icons.terrain_rounded, color: AppColors.accentLight, size: 18),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 55,
            width: double.infinity,
            child: CustomPaint(
              painter: IntensityWavePainter(
                intensities: intensities,
                maxIntensity: maxIntensity,
                color: AppColors.accentLight,
              ),
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildRecentNotes(MonthlyData data) {
    final daysWithNotes = data.workDays.where((d) => d.note.trim().isNotEmpty).toList();
    daysWithNotes.sort((a, b) => b.date.compareTo(a.date));

    if (daysWithNotes.isEmpty) return const SizedBox.shrink();

    final isTr = widget.lang.currentLang == 'tr';
    final title = isTr ? 'Son Notlar' : 'Recent Notes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: daysWithNotes.length,
            itemBuilder: (context, index) {
              final day = daysWithNotes[index];
              final monthName = widget.lang.monthName(day.date.month);
              final dateStr = '${day.date.day} $monthName';

              return Container(
                width: 220,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sticky_note_2_rounded, size: 14, color: AppColors.accentLight),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        day.note.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Arkaplan için tüm ekranı kaplayan, şık ve çok saydam nokta (dot) deseni
class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double spacing = 24.0;
    const double radius = 1.2;

    for (double y = 0; y < size.height + spacing; y += spacing) {
      for (double x = 0; x < size.width + spacing; x += spacing) {
        // Satırlara göre hafif kaydırma (çapraz bir his vermek için)
        final offsetX = (y / spacing) % 2 == 0 ? 0.0 : spacing / 2.0;
        canvas.drawCircle(Offset(x + offsetX, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// İş yoğunluğunu dalgalı bir alan (area chart) olarak çizen painter
class IntensityWavePainter extends CustomPainter {
  final List<double> intensities;
  final double maxIntensity;
  final Color color;

  IntensityWavePainter({
    required this.intensities,
    required this.maxIntensity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensities.isEmpty) return;

    final stepX = size.width / (intensities.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < intensities.length; i++) {
      final x = i * stepX;
      // Normalizasyon: 0'da dipte (size.height), maxIntensity'de en üstte (0)
      final normalizedY = intensities[i] / maxIntensity;
      final y = size.height - (normalizedY * size.height);
      points.add(Offset(x, y));
    }

    // Yumuşak Dalga (Bezier) Yolu Oluşturma
    final wavePath = Path();
    wavePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      // Yumuşak geçiş (spline)
      final controlPointX = (p0.dx + p1.dx) / 2;
      wavePath.cubicTo(
        controlPointX, p0.dy,
        controlPointX, p1.dy,
        p1.dx, p1.dy,
      );
    }

    // Alanı (Alt Kısmı) Boyamak İçin Yolu Kapatma
    final fillPath = Path.from(wavePath);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Boya: Yukarıdan aşağıya opasitesi azalan gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.5),
          color.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Çizgi: Dalganın üst sınır çizgisi
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(wavePath, linePaint);

    // İş gidilen noktaları işaretleme (Zirveler)
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      // Eğer o gün yoğunluk arttıysa (işe gidildiyse) küçük bir nokta koy
      // (Bunu önceki günden büyük olmasıyla veya sıfırdan büyük olmasıyla anlayabiliriz)
      if (i > 0 && intensities[i] > intensities[i - 1]) {
        canvas.drawCircle(points[i], 3.0, dotPaint);
      } else if (i == 0 && intensities[i] > 0) {
        canvas.drawCircle(points[i], 3.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant IntensityWavePainter oldDelegate) => true;
}
