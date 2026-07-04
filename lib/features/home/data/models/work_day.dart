/// Tek bir iş günü verisi
class WorkDay {
  final DateTime date;
  final bool isCityCenter; // true = şehir içi, false = şehir dışı
  final double payment;
  final String note;

  const WorkDay({
    required this.date,
    required this.isCityCenter,
    required this.payment,
    this.note = '',
  });

  WorkDay copyWith({
    DateTime? date,
    bool? isCityCenter,
    double? payment,
    String? note,
  }) {
    return WorkDay(
      date: date ?? this.date,
      isCityCenter: isCityCenter ?? this.isCityCenter,
      payment: payment ?? this.payment,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'isCityCenter': isCityCenter,
      'payment': payment,
      'note': note,
    };
  }

  factory WorkDay.fromJson(Map<String, dynamic> json) {
    return WorkDay(
      date: DateTime.parse(json['date'] as String),
      isCityCenter: json['isCityCenter'] as bool,
      payment: (json['payment'] as num).toDouble(),
      note: json['note'] as String? ?? '',
    );
  }
}
