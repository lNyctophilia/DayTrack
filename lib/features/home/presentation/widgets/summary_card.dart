import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/language_service.dart';

/// Takvim altında toplam gün ve kazanç özeti
class SummaryCard extends StatelessWidget {
  final int totalDays;
  final double totalEarnings;
  final LanguageService lang;

  const SummaryCard({
    super.key,
    required this.totalDays,
    required this.totalEarnings,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = lang.tr('currency_symbol');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          // Toplam Gün
          Expanded(
            child: _SummaryItem(
              icon: Icons.calendar_today_rounded,
              iconColor: AppColors.accentLight,
              label: lang.tr('total_days'),
              value: '$totalDays',
            ),
          ),
          // Ayırıcı
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          // Toplam Kazanç
          Expanded(
            child: _SummaryItem(
              icon: Icons.payments_rounded,
              iconColor: AppColors.success,
              label: lang.tr('total_earnings'),
              value: '$currencySymbol${_formatMoney(totalEarnings)}',
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]}.',
      );
    }
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
      (m) => '${m[1]}.',
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
