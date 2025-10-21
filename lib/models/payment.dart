class Payment {
  final int? id;
  final String customer;
  final String date; // ISO String
  final double amount;

  Payment({
    this.id,
    required this.customer,
    required this.date,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer': customer,
      'date': date,
      'amount': amount,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      customer: map['customer'],
      date: map['date'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
