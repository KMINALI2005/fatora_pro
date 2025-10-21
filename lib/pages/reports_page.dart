import 'package:fatora_pro/models/account.dart';
import 'package:fatora_pro/models/invoice.dart';
import 'package:fatora_pro/providers/app_provider.dart';
import 'package:fatora_pro/utils/formatters.dart';
import 'package:fatora_pro/widgets/gradient_button.dart';
import 'package:fatora_pro/widgets/section_card.dart';
import 'package:fatora_pro/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _setReportDateRange('month'); // تعيين افتراضي
  }

  void _setReportDateRange(String preset) {
    final today = DateTime.now();
    DateTime startDate = today;

    switch (preset) {
      case 'today':
        startDate = today;
        break;
      case 'week':
        startDate = today.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = today.subtract(const Duration(days: 30));
        break;
      case 'year':
        startDate = today.subtract(const Duration(days: 365));
        break;
    }
    
    setState(() {
      _startDate = startDate;
      _endDate = today;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _generateReport() {
    final provider = context.read<AppProvider>();
    final startDateStr = Formatters.formatDate(_startDate);
    final endDateStr = Formatters.formatDate(_endDate);

    final List<Invoice> filteredInvoices = provider.invoices.where((inv) {
      return inv.date.compareTo(startDateStr) >= 0 && inv.date.compareTo(endDateStr) <= 0;
    }).toList();
    
    if (filteredInvoices.isEmpty) {
      setState(() {
        _reportData = {'isEmpty': true};
      });
      return;
    }
    
    // حساب الإحصائيات
    double totalSales = 0;
    double totalPayments = 0;
    final Map<String, double> productStats = {};
    final Map<String, double> customerStats = {};

    for (var inv in filteredInvoices) {
      totalSales += inv.total;
      totalPayments += inv.payment;
      
      // إحصائيات الزبائن
      customerStats.update(inv.customer, (value) => value + inv.total, ifAbsent: () => inv.total);
      
      // إحصائيات المنتجات
      for (var item in inv.items) {
         productStats.update(item.product, (value) => value + item.total, ifAbsent: () => item.total);
      }
    }
    
    // إجمالي الديون الكلي (لا يعتمد على التاريخ)
    final double totalRemaining = provider.accounts
        .where((acc) => acc.finalBalance > 0)
        .fold(0.0, (sum, acc) => sum + acc.finalBalance);
    
    // فرز
    final topProducts = productStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final topCustomers = customerStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _reportData = {
        'isEmpty': false,
        'invoiceCount': filteredInvoices.length,
        'totalSales': totalSales,
        'totalPayments': totalPayments,
        'totalRemaining': totalRemaining,
        'avgInvoice': totalSales / filteredInvoices.length,
        'topProducts': topProducts.take(10).toList(),
        'topCustomers': topCustomers.take(10).toList(),
      };
    });
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // 1. اختيار الفترة
          _buildDateRangePicker(),
          
          // 2. نتائج التقرير
          _buildReportResults(),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('📅 فترة التحليل', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilterChip(label: const Text('📅 اليوم'), selected: false, onSelected: (_) => _setReportDateRange('today')),
              FilterChip(label: const Text('📅 هذا الأسبوع'), selected: false, onSelected: (_) => _setReportDateRange('week')),
              FilterChip(label: const Text('📅 هذا الشهر'), selected: true, onSelected: (_) => _setReportDateRange('month')),
              FilterChip(label: const Text('📅 هذه السنة'), selected: false, onSelected: (_) => _setReportDateRange('year')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'من تاريخ:'),
                    child: Text(Formatters.formatDate(_startDate)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'إلى تاريخ:'),
                    child: Text(Formatters.formatDate(_endDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GradientButton(
            onPressed: _generateReport,
            child: const Text('🔍 عرض التقرير'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportResults() {
    if (_reportData == null) {
      return const SizedBox.shrink();
    }
    
    if (_reportData!['isEmpty'] == true) {
      return SectionCard(
        child: Center(
          child: Text(
            '📊 لا توجد بيانات لعرضها في الفترة المحددة',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ),
      );
    }
    
    final Map<String, dynamic> stats = _reportData!;
    final Color primary = Theme.of(context).primaryColor;

    return Column(
      children: [
        // إحصائيات المبيعات
        SectionCard(
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              StatCard(label: 'عدد الفواتير', value: Formatters.formatCurrency(stats['invoiceCount']), color: primary),
              StatCard(label: 'إجمالي المبيعات', value: Formatters.formatCurrency(stats['totalSales']), color: Colors.green.shade700),
              StatCard(label: 'إجمالي المدفوعات', value: Formatters.formatCurrency(stats['totalPayments']), color: Colors.orange.shade700),
              StatCard(label: 'إجمالي المتبقي (الكلي)', value: Formatters.formatCurrency(stats['totalRemaining']), color: Colors.red.shade700),
              StatCard(label: 'متوسط الفاتورة', value: Formatters.formatCurrency(stats['avgInvoice']), color: primary),
            ],
          ),
        ),
        
        // أكثر المنتجات مبيعاً
        _buildTopProductsTable(stats['topProducts']),
        
        // أكثر الزبائن شراءً
        _buildTopCustomersTable(stats['topCustomers']),
      ],
    );
  }
  
  Widget _buildTopProductsTable(List<MapEntry<String, double>> products) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('🏆 أكثر 10 منتجات مبيعًا', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('المنتج')),
                DataColumn(label: Text('إجمالي المبيعات')),
              ],
              rows: products.asMap().entries.map((entry) {
                return DataRow(cells: [
                  DataCell(Text((entry.key + 1).toString())),
                  DataCell(Text(entry.value.key)),
                  DataCell(Text('${Formatters.formatCurrency(entry.value.value)} د', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopCustomersTable(List<MapEntry<String, double>> customers) {
     return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('👥 أكثر 10 زبائن شراءً', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('الزبون')),
                DataColumn(label: Text('إجمالي المشتريات')),
              ],
              rows: customers.asMap().entries.map((entry) {
                return DataRow(cells: [
                  DataCell(Text((entry.key + 1).toString())),
                  DataCell(Text(entry.value.key)),
                  DataCell(Text('${Formatters.formatCurrency(entry.value.value)} د', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
