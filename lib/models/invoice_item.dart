import 'dart:convert';

class InvoiceItem {
  final String product;
  final double quantity;
  final double price;
  final double total;
  final String notes;

  InvoiceItem({
    required this.product,
    required this.quantity,
    required this.price,
    required this.total,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'product': product,
      'quantity': quantity,
      'price': price,
      'total': total,
      'notes': notes,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      product: map['product'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
    );
  }
  
  static String encode(List<InvoiceItem> items) => json.encode(
        items.map<Map<String, dynamic>>((item) => item.toMap()).toList(),
      );

  static List<InvoiceItem> decode(String items) =>
      (json.decode(items) as List<dynamic>)
          .map<InvoiceItem>((item) => InvoiceItem.fromMap(item))
          .toList();
}
