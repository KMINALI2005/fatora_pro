import 'package:fatora_pro/models/invoice.dart';
import 'package:fatora_pro/models/payment.dart';

// كلاس مساعد لتوحيد الفواتير والدفعات في سجل واحد
class Transaction {
  final DateTime date;
  final String type; // 'invoice' or 'payment'
  final String description;
  final double debtChange; // (total)
  final double paymentChange; // (payment or amount)
  final double balanceAfter;
  final dynamic originalObject; // Invoice or Payment

  Transaction({
    required this.date,
    required this.type,
    required this.description,
    required this.debtChange,
    required this.paymentChange,
    required this.balanceAfter,
    required this.originalObject,
  });
}

class Account {
  final String customerName;
  final double finalBalance;
  final DateTime? lastActivityDate;
  final List<Transaction> history; // مرتبة من الأقدم للأحدث

  Account({
    required this.customerName,
    required this.finalBalance,
    this.lastActivityDate,
    required this.history,
  });
}
