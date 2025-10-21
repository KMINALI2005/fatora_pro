import 'package:fatora_pro/models/account.dart';
import 'package:fatora_pro/models/invoice.dart';
import 'package:fatora_pro/models/payment.dart';
import 'package:fatora_pro/models/product.dart';
import 'package:fatora_pro/services/database_helper.dart';
import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Product> _products = [];
  List<Product> get products => _products;

  List<Invoice> _invoices = [];
  List<Invoice> get invoices => _invoices;

  List<Payment> _payments = [];
  List<Payment> get payments => _payments;
  
  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;
  
  Map<String, double> _customerDebts = {};
  Map<String, double> get customerDebts => _customerDebts;

  // === تحميل البيانات ===
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    _products = await _db.getAllProducts();
    _invoices = await _db.getAllInvoices();
    _payments = await _db.getAllPayments();
    
    _calculateAccounts(); // حساب الديون

    _isLoading = false;
    notifyListeners();
  }

  // === منطق حساب الديون (الأهم) ===
  // هذا يحاكي دالة displayAccounts() في JS
  void _calculateAccounts() {
    List<Account> calculatedAccounts = [];
    Map<String, double> customerDebts = {};
    
    // 1. جمع كل الزبائن
    final allCustomers = <String>{};
    for (var inv in _invoices) { allCustomers.add(inv.customer); }
    for (var pay in _payments) { allCustomers.add(pay.customer); }

    // 2. حساب رصيد كل زبون
    for (var customerName in allCustomers) {
      final customerInvoices = _invoices.where((i) => i.customer == customerName);
      final customerPayments = _payments.where((p) => p.customer == customerName);
      
      // 3. دمج الفواتير والدفعات في قائمة واحدة
      List<dynamic> combinedTransactions = [];
      combinedTransactions.addAll(customerInvoices);
      combinedTransactions.addAll(customerPayments);

      // 4. ترتيب الحركات حسب التاريخ (الأقدم أولاً)
      combinedTransactions.sort((a, b) {
        DateTime dateA = DateTime.parse(a.date);
        DateTime dateB = DateTime.parse(b.date);
        
        // إذا كانا في نفس اليوم، الفاتورة تأتي قبل الدفعة (إذا كانت ID)
        if (dateA.isAtSameMomentAs(dateB)) {
          if (a is Invoice && b is Payment) return -1;
          if (a is Payment && b is Invoice) return 1;
          // إذا كانا فاتورتين، رتب حسب ID
          if(a is Invoice && b is Invoice) return (a.id ?? 0).compareTo(b.id ?? 0);
        }
        return dateA.compareTo(dateB);
      });

      double runningBalance = 0.0;
      List<Transaction> history = [];
      
      // 5. حساب الرصيد التراكمي
      if (combinedTransactions.isNotEmpty && combinedTransactions.first is Invoice) {
        // الرصيد الافتتاحي هو "الرصيد السابق" لأول فاتورة
        runningBalance = (combinedTransactions.first as Invoice).previousBalance;
      }
      
      for (var tx in combinedTransactions) {
        if (tx is Invoice) {
          // الفاتورة تضيف (المجموع) وتطرح (المدفوع مع الفاتورة)
          double change = tx.total - tx.payment;
          runningBalance += change;
          history.add(Transaction(
            date: DateTime.parse(tx.date),
            type: 'invoice',
            description: 'فاتورة #${tx.id}',
            debtChange: tx.total,
            paymentChange: tx.payment,
            balanceAfter: runningBalance,
            originalObject: tx,
          ));
        } else if (tx is Payment) {
          // الدفعة تطرح (المبلغ)
          runningBalance -= tx.amount;
           history.add(Transaction(
            date: DateTime.parse(tx.date),
            type: 'payment',
            description: 'دفعة مالية',
            debtChange: 0,
            paymentChange: tx.amount,
            balanceAfter: runningBalance,
            originalObject: tx,
          ));
        }
      }
      
      calculatedAccounts.add(Account(
        customerName: customerName,
        finalBalance: runningBalance,
        lastActivityDate: history.isNotEmpty ? history.last.date : null,
        history: history, // مرتبة من الأقدم للأحدث
      ));
      
      customerDebts[customerName] = runningBalance;
    }
    
    _accounts = calculatedAccounts;
    _customerDebts = customerDebts;
  }
  
  // === دوال المنتجات ===
  Future<void> addOrUpdateProduct(String name, double price) async {
    try {
      final existing = await _db.getProductByName(name);
      // تحديث السعر
      await _db.updateProduct(Product(id: existing.id, name: name, price: price));
    } catch (e) {
      // إضافة جديد
      await _db.insertProduct(Product(name: name, price: price));
    }
    await loadAllData(); // إعادة تحميل الكل
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    await loadAllData();
  }
  
  Future<void> clearAllProducts() async {
    await _db.clearAllProducts();
    await loadAllData();
  }
  
  Future<void> bulkAddProducts(List<Product> products) async {
    await _db.bulkInsertProducts(products);
    await loadAllData();
  }

  // === دوال الفواتير ===
  Future<void> saveInvoice(Invoice invoice) async {
    await _db.insertInvoice(invoice);
    await loadAllData();
  }
  
  Future<void> updateInvoice(Invoice invoice) async {
    await _db.updateInvoice(invoice);
    await loadAllData();
  }
  
  Future<void> deleteInvoice(int id) async {
    await _db.deleteInvoice(id);
    await loadAllData();
  }
  
  Future<void> clearAllInvoices() async {
    await _db.clearAllInvoices();
    await loadAllData();
  }
  
  Future<void> bulkAddInvoices(List<Invoice> invoices) async {
    await _db.bulkInsertInvoices(invoices);
    await loadAllData();
  }
  
  Future<void> updateInvoicePrintHistory(Invoice invoice) async {
     String today = DateTime.now().toIso8601String().split('T').first;
     invoice.printHistory[today] = (invoice.printHistory[today] ?? 0) + 1;
     await _db.updateInvoice(invoice);
     // تحديث جزئي بدلاً من إعادة تحميل الكل لتحسين الأداء
     int index = _invoices.indexWhere((inv) => inv.id == invoice.id);
     if (index != -1) {
       _invoices[index] = invoice;
       notifyListeners();
     }
  }

  // === دوال الدفعات ===
  Future<void> addPayment(String customerName, double amount, DateTime date) async {
    await _db.insertPayment(Payment(
      customer: customerName,
      date: date.toIso8601String(),
      amount: amount,
    ));
    await loadAllData(); // يجب إعادة تحميل الكل لإعادة حساب الديون
  }
}
