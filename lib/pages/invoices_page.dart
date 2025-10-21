import 'package:fatora_pro/models/account.dart';  // ✅ أضف هذا في أعلى الملف
import 'package:fatora_pro/models/invoice.dart';
import 'package:fatora_pro/pages/create_invoice_page.dart';
import 'package:fatora_pro/providers/app_provider.dart';
import 'package:fatora_pro/services/file_service.dart';
import 'package:fatora_pro/services/pdf_service.dart';
import 'package:fatora_pro/utils/formatters.dart';
import 'package:fatora_pro/widgets/gradient_button.dart';
import 'package:fatora_pro/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum InvoiceFilter { all, paid, unpaid }

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({Key? key}) : super(key: key);

  @override
  _InvoicesPageState createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  InvoiceFilter _currentFilter = InvoiceFilter.all;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final PdfService _pdfService = PdfService();
  late final FileService _fileService;
  
  @override
  void initState() {
    super.initState();
    _fileService = FileService(context.read<AppProvider>());
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _setFilter(InvoiceFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  void _confirmClearAllInvoices() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تحذير!'),
        content: Text('هل أنت متأكد من حذف جميع الفواتير بشكل نهائي؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('إلغاء')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AppProvider>().clearAllInvoices();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف جميع الفواتير'), backgroundColor: Colors.green),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('نعم، احذف الكل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 1. تطبيق الفلاتر والبحث
        final filteredInvoices = provider.invoices.where((inv) {
          final matchesFilter =
              _currentFilter == InvoiceFilter.all ||
              (_currentFilter == InvoiceFilter.paid && inv.isPaid) ||
              (_currentFilter == InvoiceFilter.unpaid && !inv.isPaid);

          final matchesSearch =
              _searchQuery.isEmpty ||
              inv.customer.toLowerCase().contains(_searchQuery) ||
              inv.id.toString().contains(_searchQuery);

          return matchesFilter && matchesSearch;
        }).toList();
        
        // 2. تجميع حسب الزبون
        final Map<String, List<Invoice>> groupedInvoices = {};
        for (var inv in filteredInvoices) {
          groupedInvoices.putIfAbsent(inv.customer, () => []).add(inv);
        }
        
        // 3. حساب الإحصائيات
        final stats = _calculateStats(provider.accounts, provider.invoices.length);

        return ListView(
          padding: const EdgeInsets.all(12.0),
          children: [
            // الإحصائيات السريعة
            _buildStatsSummary(stats),
            
            // أزرار الاستيراد والتصدير
            _buildImportExportActions(),

            // فلاتر الفواتير
            _buildFilters(),

            // البحث
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: '🔍 بحث (باسم الزبون أو رقم الفاتورة):',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.clear),
                ),
                onTap: () {
                  if (_searchController.text.isNotEmpty) {
                    _searchController.clear();
                  }
                },
              ),
            ),
            
            // قائمة الفواتير
            _buildInvoicesList(groupedInvoices, provider.customerDebts),
          ],
        );
      },
    );
  }

  Map<String, double> _calculateStats(List<Account> accounts, int totalInvoices) {
    double totalDebts = 0;
    int totalCustomers = accounts.length;
    
    for (var acc in accounts) {
      if (acc.finalBalance > 0) {
        totalDebts += acc.finalBalance;
      }
    }
    
    return {
      'totalCustomers': totalCustomers.toDouble(),
      'totalInvoices': totalInvoices.toDouble(),
      'totalDebts': totalDebts,
    };
  }

  Widget _buildStatsSummary(Map<String, double> stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StatCard(
              label: 'إجمالي الزبائن',
              value: Formatters.formatCurrency(stats['totalCustomers'] ?? 0),
              color: Theme.of(context).primaryColor,
            ),
            StatCard(
              label: 'إجمالي الفواتير',
              value: Formatters.formatCurrency(stats['totalInvoices'] ?? 0),
              color: Colors.orange.shade700,
            ),
            StatCard(
              label: 'إجمالي المتبقي',
              value: Formatters.formatCurrency(stats['totalDebts'] ?? 0),
              color: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImportExportActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          GradientButton(
            onPressed: () => _fileService.importInvoices(context),
            colors: GradientButton.successGradient,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.upload), SizedBox(width: 8), Text('استيراد فواتير')]),
          ),
          GradientButton(
            onPressed: () => _fileService.exportInvoices(context),
            colors: GradientButton.primaryGradient,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.download), SizedBox(width: 8), Text('تصدير فواتير')]),
          ),
           GradientButton(
            onPressed: _confirmClearAllInvoices,
            colors: GradientButton.dangerGradient,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.delete_forever), SizedBox(width: 8), Text('مسح الكل')]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return ToggleButtons(
      isSelected: [
        _currentFilter == InvoiceFilter.all,
        _currentFilter == InvoiceFilter.unpaid,
        _currentFilter == InvoiceFilter.paid,
      ],
      onPressed: (index) {
        if (index == 0) _setFilter(InvoiceFilter.all);
        if (index == 1) _setFilter(InvoiceFilter.unpaid);
        if (index == 2) _setFilter(InvoiceFilter.paid);
      },
      borderRadius: BorderRadius.circular(14),
      selectedColor: Colors.white,
      color: Theme.of(context).primaryColor,
      fillColor: Theme.of(context).primaryColor,
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Row(children: [Icon(Icons.list), SizedBox(width: 8), Text('📋 الكل')])),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Row(children: [Icon(Icons.close), SizedBox(width: 8), Text('❌ غير مسددة')])),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Row(children: [Icon(Icons.check), SizedBox(width: 8), Text('✅ مسددة')])),
      ],
    );
  }

  Widget _buildInvoicesList(Map<String, List<Invoice>> groupedInvoices, Map<String, double> customerDebts) {
    if (groupedInvoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text('📋 لا توجد فواتير تطابق البحث أو الفلتر', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }
    
    final sortedCustomers = groupedInvoices.keys.toList()
      ..sort((a, b) => groupedInvoices[b]!.first.id!.compareTo(groupedInvoices[a]!.first.id!));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedCustomers.length,
      itemBuilder: (context, index) {
        final customerName = sortedCustomers[index];
        final invoices = groupedInvoices[customerName]!;
        final totalDebt = customerDebts[customerName] ?? 0.0;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.blue.shade100, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: PageStorageKey(customerName), // للحفاظ على الحالة عند التمرير
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            leading: Icon(Icons.person, color: Theme.of(context).primaryColor),
            title: Text(customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            subtitle: Text('🧾 ${invoices.length} فواتير | 📅 آخر فاتورة: ${invoices.first.date}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: totalDebt > 0 ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: totalDebt > 0 ? Colors.red.shade200 : Colors.green.shade200)
              ),
              child: Text(
                '${Formatters.formatCurrency(totalDebt)} د',
                style: TextStyle(color: totalDebt > 0 ? Colors.red.shade700 : Colors.green.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            children: invoices.map((inv) => _buildInvoiceTile(inv)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceTile(Invoice inv) {
    String today = DateTime.now().toIso8601String().split('T').first;
    int printCount = inv.printHistory[today] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.3),
        border: Border(top: BorderSide(color: Colors.blue.shade100))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('فاتورة #${inv.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
              Text(inv.date, style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text('الإجمالي: ${Formatters.formatCurrency(inv.total)}'),
                Text('المتبقي: ${Formatters.formatCurrency(inv.remainingBalance)}', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: inv.isPaid ? Colors.green.shade700 : Colors.red.shade700,
                )),
             ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر الطباعة
              TextButton.icon(
                icon: const Icon(Icons.print),
                label: Text(printCount > 0 ? 'طباعة ($printCount)' : 'طباعة'),
                onPressed: () async {
                  await _pdfService.printInvoice(inv);
                  // تحديث الـ Provider
                  context.read<AppProvider>().updateInvoicePrintHistory(inv);
                },
              ),
              // زر التعديل
              TextButton.icon(
                icon: const Icon(Icons.edit, color: Colors.orange),
                label: const Text('تعديل', style: TextStyle(color: Colors.orange)),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CreateInvoicePage(invoiceToEdit: inv),
                  ));
                },
              ),
              // زر الحذف
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('حذف', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('تأكيد الحذف'),
                      content: Text('هل أنت متأكد من حذف الفاتورة رقم ${inv.id}؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('إلغاء')),
                        FilledButton(onPressed: (){
                           Navigator.of(ctx).pop();
                           context.read<AppProvider>().deleteInvoice(inv.id!);
                        }, child: Text('نعم، احذف')),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
