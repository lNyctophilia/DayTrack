import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/work_day.dart';

/// Gün giriş formu — Bottom Sheet
class DayEntrySheet extends StatefulWidget {
  final DateTime date;
  final WorkDay? existingEntry;
  final StorageService storage;
  final LanguageService lang;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  const DayEntrySheet({
    super.key,
    required this.date,
    this.existingEntry,
    required this.storage,
    required this.lang,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  State<DayEntrySheet> createState() => _DayEntrySheetState();
}

class _DayEntrySheetState extends State<DayEntrySheet> {
  late bool _isCityCenter;
  late TextEditingController _paymentController;
  late TextEditingController _noteController;

  bool get isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _isCityCenter = widget.existingEntry?.isCityCenter ?? true;

    final defaultPayment = _isCityCenter
        ? widget.storage.getCityInnerPayment()
        : widget.storage.getCityOuterPayment();

    _paymentController = TextEditingController(
      text: widget.existingEntry != null
          ? _formatPaymentValue(widget.existingEntry!.payment)
          : _formatPaymentValue(defaultPayment),
    );

    _noteController = TextEditingController(
      text: widget.existingEntry?.note ?? '',
    );
  }

  String _formatPaymentValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  void dispose() {
    _paymentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onCityTypeChanged(bool isCityCenter) {
    setState(() {
      _isCityCenter = isCityCenter;
      // Ücret otomatik güncelle (sadece kullanıcı manuel değiştirmediyse)
      if (!isEditing) {
        final payment = isCityCenter
            ? widget.storage.getCityInnerPayment()
            : widget.storage.getCityOuterPayment();
        _paymentController.text = _formatPaymentValue(payment);
      }
    });
  }

  Future<void> _save() async {
    final payment =
        double.tryParse(_paymentController.text.replaceAll(',', '.')) ?? 0;

    final workDay = WorkDay(
      date: widget.date,
      isCityCenter: _isCityCenter,
      payment: payment,
      note: _noteController.text.trim(),
    );

    await widget.storage.saveWorkDay(workDay);
    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          widget.lang.tr('delete'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          widget.lang.tr('delete_confirm'),
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
      await widget.storage.deleteWorkDay(widget.date);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDeleted();
      }
    }
  }

  String _getFormattedDate() {
    final dayNames = widget.lang.currentLang == 'tr'
        ? [
            'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
            'Cuma', 'Cumartesi', 'Pazar'
          ]
        : [
            'Monday', 'Tuesday', 'Wednesday', 'Thursday',
            'Friday', 'Saturday', 'Sunday'
          ];

    final dayName = dayNames[widget.date.weekday - 1];
    final monthName = widget.lang.monthName(widget.date.month);

    return '${widget.date.day} $monthName ${widget.date.year}, $dayName';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarih başlığı
            Text(
              _getFormattedDate(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Şehir İçi / Dışı seçimi
            _buildCityTypeSelector(),
            const SizedBox(height: 20),

            // Ücret
            Text(
              widget.lang.tr('payment'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _paymentController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: '${widget.lang.tr('currency_symbol')} ',
                prefixStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentLight,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Not
            Text(
              widget.lang.tr('note'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.lang.tr('note_hint'),
              ),
            ),
            const SizedBox(height: 24),

            // Butonlar
            Row(
              children: [
                // Sil butonu (sadece düzenleme modunda)
                if (isEditing)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: Text(widget.lang.tr('delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (isEditing) const SizedBox(width: 12),
                // Kaydet butonu
                Expanded(
                  flex: isEditing ? 2 : 1,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Text(widget.lang.tr('save')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildCityOption(
            label: widget.lang.tr('city_inner'),
            isSelected: _isCityCenter,
            color: AppColors.cityInner,
            onTap: () => _onCityTypeChanged(true),
          ),
          _buildCityOption(
            label: widget.lang.tr('city_outer'),
            isSelected: !_isCityCenter,
            color: AppColors.cityOuter,
            onTap: () => _onCityTypeChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildCityOption({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
