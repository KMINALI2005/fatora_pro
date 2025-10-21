import 'dart:convert';
import 'package:fatora_pro/models/invoice_item.dart';

class Invoice {
  final int? id;
  final String customer;
  final String date; // ISO String: YYYY-MM-DD
  final List<InvoiceItem> items;
  final double total;
  final double previousBalance;
  final double payment;
  final Map<String, int> printHistory; // لتتبع عدد مرات الطباعة

  Invoice({
    this.id,
    required this.customer,
    required this.date,
    required this.items,
    required this.total,
    this.previousBalance = 0.0,
    this.payment = 0.0,
    Map<String, int>? printHistory,
  }) : printHistory = printHistory ?? {};

  double get remainingBalance => (total + previousBalance) - payment;
  bool get isPaid => remainingBalance <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer': customer,
      'date': date,
      'items': InvoiceItem.encode(items),
      'total': total,
      'previousBalance': previousBalance,
      'payment': payment,
      'printHistory': json.encode(printHistory),
    };
  }
  
  // دالة للحفظ بدون ID (للاستيراد)
  Map<String, dynamic> toMapWithoutId() {
    return {
      'customer': customer,
      'date': date,
      'items': InvoiceItem.encode(items),
      'total': total,
      'previousBalance': previousBalance,
      'payment': payment,
      'printHistory': json.encode(printHistory),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      customer: map['customer'] ?? 'زبون غير محدد',
      date: map['date'] ?? DateTime.now().toIso8601String(),
      items: InvoiceItem.decode(map['items'] ?? '[]'),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      previousBalance: (map['previousBalance'] as num?)?.toDouble() ?? 0.0,
      payment: (map['payment'] as num?)?.toDouble() ?? 0.0,
      printHistory: map['printHistory'] != null
          ? Map<String, int>.from(json.decode(map['printHistory']))
          : {},
    );
  }
}
