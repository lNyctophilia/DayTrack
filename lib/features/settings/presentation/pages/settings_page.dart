import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';

/// Ayarlar Sayfası
class SettingsPage extends StatefulWidget {
  final StorageService storage;
  final LanguageService lang;
  final VoidCallback onDataDeleted;

  const SettingsPage({
    super.key,
    required this.storage,
    required this.lang,
    required this.onDataDeleted,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _cityInnerController;
  late TextEditingController _cityOuterController;

  static String get _appVersion => AppConfig.version;
  static String get _developerName => AppConfig.developerName;

  @override
  void initState() {
    super.initState();
    _cityInnerController = TextEditingController(
      text: _formatValue(widget.storage.getCityInnerPayment()),
    );
    _cityOuterController = TextEditingController(
      text: _formatValue(widget.storage.getCityOuterPayment()),
    );
  }

  String _formatValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  void dispose() {
    _savePayments();
    _cityInnerController.dispose();
    _cityOuterController.dispose();
    super.dispose();
  }

  Future<void> _savePayments() async {
    final inner =
        double.tryParse(_cityInnerController.text.replaceAll(',', '.'));
    final outer =
        double.tryParse(_cityOuterController.text.replaceAll(',', '.'));

    if (inner != null) await widget.storage.setCityInnerPayment(inner);
    if (outer != null) await widget.storage.setCityOuterPayment(outer);
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          widget.lang.tr('delete_all_data'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          widget.lang.tr('delete_all_confirm'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.lang.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(widget.lang.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storage.deleteAllData();
      widget.onDataDeleted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.lang.tr('data_deleted')),
            backgroundColor: AppColors.card,
          ),
        );
      }
    }
  }

  void _showIOSInstallPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentLight.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.ios_share_rounded,
                color: AppColors.accentLight,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.lang.tr('install_ios_title'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          widget.lang.tr('install_ios_desc'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lang.tr('settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ─── Varsayılan Ücretler ────────────────────────
          _buildSectionHeader(widget.lang.tr('default_payments')),
          _buildPaymentTile(
            label: widget.lang.tr('city_inner_payment'),
            controller: _cityInnerController,
            color: AppColors.cityInner,
            icon: Icons.location_city_rounded,
          ),
          _buildPaymentTile(
            label: widget.lang.tr('city_outer_payment'),
            controller: _cityOuterController,
            color: AppColors.cityOuter,
            icon: Icons.flight_takeoff_rounded,
          ),
          const SizedBox(height: 8),

          // ─── Genel ─────────────────────────────────────
          _buildSectionHeader(widget.lang.tr('general')),
          _buildLanguageTile(),
          if (kIsWeb) _buildIOSInstallTile(),
          const SizedBox(height: 8),

          // ─── Veri ──────────────────────────────────────
          _buildSectionHeader(widget.lang.tr('data')),
          _buildDeleteDataTile(),
          const SizedBox(height: 24),

          // ─── Hakkında ──────────────────────────────────
          _buildSectionHeader(widget.lang.tr('about')),
          _buildAboutSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.accentLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPaymentTile({
    required String label,
    required TextEditingController controller,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    ],
                    onChanged: (_) => _savePayments(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      prefixText:
                          '${widget.lang.tr('currency_symbol')} ',
                      prefixStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppColors.accentLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            widget.lang.tr('language'),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Dil seçici
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _buildLangChip('TR', 'tr'),
                _buildLangChip('EN', 'en'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String label, String langCode) {
    final isSelected = widget.lang.currentLang == langCode;
    return GestureDetector(
      onTap: () {
        widget.lang.setLanguage(langCode);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildIOSInstallTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accentLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.apple_rounded,
            color: AppColors.accentLight,
            size: 22,
          ),
        ),
        title: Text(
          widget.lang.tr('install_ios'),
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textHint,
        ),
        onTap: _showIOSInstallPopup,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildDeleteDataTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.delete_forever_rounded,
            color: AppColors.danger,
            size: 22,
          ),
        ),
        title: Text(
          widget.lang.tr('delete_all_data'),
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.danger,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textHint,
        ),
        onTap: _deleteAllData,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // App icon placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.accentLight,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Day Track',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.lang.tr('version')} $_appVersion',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          Text(
            _developerName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.accentLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© ${DateTime.now().year} · ${widget.lang.tr('all_rights_reserved')}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
