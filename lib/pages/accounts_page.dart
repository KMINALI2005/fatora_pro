import 'package:fatora_pro/models/account.dart';
import 'package:fatora_pro/providers/app_provider.dart';
import 'package:fatora_pro/utils/formatters.dart';
import 'package:fatora_pro/widgets/gradient_button.dart';
import 'package:fatora_pro/widgets/section_card.dart';
import 'package:fatora_pro/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum AccountSort { debtDesc, debtAsc, nameAsc, nameDesc, dateDesc }

class AccountsPage extends StatefulWidget {
  const AccountsPage({Key? key}) : super(key: key);

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  AccountSort _sortOption = AccountSort.debtDesc;
  
  // Controller لكل زبون لإضافة دفعة
  final Map<String, TextEditingController> _paymentControllers = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _paymentControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
  
  void _addDebtPayment(String customerName, double amount) {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح'), backgroundColor: Colors.red),
      );
      return;
    }
    
    context.read<AppProvider>().addPayment(customerName, amount, DateTime.now());
    
    // إفراغ الحقل
    _paymentControllers[customerName]?.clear();
    FocusScope.of(context).unfocus();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم تسجيل الدفعة بنجاح'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 1. حساب الإحصائيات
        final stats = _calculateStats(provider.accounts);
        
        // 2. الفلترة والترتيب
        final filteredAccounts = _filterAndSort(provider.accounts);
        
        return ListView(
          padding: const EdgeInsets.all(12.0),
          children: [
            // الإحصائيات السريعة
            _buildStatsSummary(stats),
            
            // البحث والترتيب
            _buildSearchAndSort(),
            
            // قائمة الحسابات
            _buildAccountsList(filteredAccounts),
          ],
        );
      },
    );
  }
  
  List<Account> _filterAndSort(List<Account> accounts) {
    List<Account> filtered = accounts.where((acc) => 
      acc.customerName.toLowerCase().contains(_searchQuery)
    ).toList();
    
    filtered.sort((a, b) {
      switch (_sortOption) {
        case AccountSort.debtDesc:
          return b.finalBalance.compareTo(a.finalBalance);
        case AccountSort.debtAsc:
          return a.finalBalance.compareTo(b.finalBalance);
        case AccountSort.nameAsc:
          return a.customerName.compareTo(b.customerName);
        case AccountSort.nameDesc:
          return b.customerName.compareTo(a.customerName);
        case AccountSort.dateDesc:
          return (b.lastActivityDate ?? DateTime(0)).compareTo(a.lastActivityDate ?? DateTime(0));
      }
    });
    
    return filtered;
  }

  Map<String, double> _calculateStats(List<Account> accounts) {
    double totalDebts = 0;
    int customersWithDebts = 0;
    int paidCustomers = 0;
    
    for (var acc in accounts) {
      if (acc.finalBalance > 0) {
        totalDebts += acc.finalBalance;
        customersWithDebts++;
      } else {
        paidCustomers++;
      }
    }
    
    double avgDebt = customersWithDebts > 0 ? totalDebts / customersWithDebts : 0;
    
    return {
      'totalDebts': totalDebts,
      'customersWithDebts': customersWithDebts.toDouble(),
      'paidCustomers': paidCustomers.toDouble(),
      'avgDebt': avgDebt,
    };
  }

  Widget _buildStatsSummary(Map<String, double> stats) {
    return SectionCard(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
        children: [
          StatCard(label: 'إجمالي الديون', value: Formatters.formatCurrency(stats['totalDebts'] ?? 0), color: Colors.red.shade700),
          StatCard(label: 'عدد المدينين', value: Formatters.formatCurrency(stats['customersWithDebts'] ?? 0), color: Theme.of(context).primaryColor),
          StatCard(label: 'زبائن بلا ديون', value: Formatters.formatCurrency(stats['paidCustomers'] ?? 0), color: Colors.green.shade700),
          StatCard(label: 'متوسط الدين', value: Formatters.formatCurrency(stats['avgDebt'] ?? 0), color: Colors.orange.shade700),
        ],
      ),
    );
  }
  
  Widget _buildSearchAndSort() {
    return SectionCard(
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: '🔍 بحث عن زبون:',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AccountSort>(
            value: _sortOption,
            decoration: const InputDecoration(
              labelText: '📊 ترتيب حسب:',
              prefixIcon: Icon(Icons.sort),
            ),
            items: const [
              DropdownMenuItem(value: AccountSort.debtDesc, child: Text('الدين الأعلى أولاً')),
              DropdownMenuItem(value: AccountSort.debtAsc, child: Text('الدين الأقل أولاً')),
              DropdownMenuItem(value: AccountSort.nameAsc, child: Text('الاسم (أ - ي)')),
              DropdownMenuItem(value: AccountSort.nameDesc, child: Text('الاسم (ي - أ)')),
              DropdownMenuItem(value: AccountSort.dateDesc, child: Text('آخر حركة (الأحدث)')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sortOption = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountsList(List<Account> accounts) {
    if (accounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text('👥 لا توجد حسابات تطابق البحث', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        // التأكد من وجود controller
        _paymentControllers.putIfAbsent(account.customerName, () => TextEditingController());
        
        return _buildAccountCard(account, _paymentControllers[account.customerName]!);
      },
    );
  }
  
  Widget _buildAccountCard(Account account, TextEditingController paymentController) {
    final bool hasDebt = account.finalBalance > 0;
    final Color balanceColor = hasDebt ? Colors.red.shade700 : Colors.green.shade700;
    
    return SectionCard(
      padding: const EdgeInsets.all(0),
      child: ExpansionTile(
        key: PageStorageKey(account.customerName),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: const Border(), // لإزالة الحدود الداخلية
        title: Text(account.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        subtitle: Text('آخر حركة: ${account.lastActivityDate != null ? Formatters.formatDate(account.lastActivityDate!) : "N/A"}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('الحساب النهائي:', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(
              '${Formatters.formatCurrency(account.finalBalance)} د',
              style: TextStyle(color: balanceColor, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        children: [
          // 1. إضافة دفعة
          _buildAddPaymentForm(account.customerName, paymentController),
          
          // 2. سجل الحركات
          _buildHistoryTable(account.history),
        ],
      ),
    );
  }
  
  Widget _buildAddPaymentForm(String customerName, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue.shade50.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💰 تسديد دين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'أدخل المبلغ الواصل...', filled: true, fillColor: Colors.white),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              GradientButton(
                onPressed: () {
                  final amount = Formatters.parseDouble(controller.text);
                  _addDebtPayment(customerName, amount);
                },
                colors: GradientButton.successGradient,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: const Text('✅ تسديد'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryTable(List<Transaction> history) {
    // عرض أحدث 10 حركات
    final recentHistory = history.reversed.take(10).toList();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📜 سجل الحركات (الأحدث أولاً)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('الحركة')),
                DataColumn(label: Text('دين (+)')),
                DataColumn(label: Text('واصل (-)')),
                DataColumn(label: Text('المتبقي')),
              ],
              rows: recentHistory.map((tx) {
                return DataRow(cells: [
                  DataCell(Text(Formatters.formatDate(tx.date))),
                  DataCell(Text(tx.description, style: TextStyle(fontWeight: FontWeight.bold, color: tx.type == 'invoice' ? Theme.of(context).primaryColor : Colors.green.shade700))),
                  DataCell(Text(tx.debtChange > 0 ? Formatters.formatCurrency(tx.debtChange) : '-', style: TextStyle(color: Theme.of(context).primaryColor))),
                  DataCell(Text(tx.paymentChange > 0 ? Formatters.formatCurrency(tx.paymentChange) : '-', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold))),
                  DataCell(Text(Formatters.formatCurrency(tx.balanceAfter), style: TextStyle(fontWeight: FontWeight.bold, color: tx.balanceAfter > 0 ? Colors.red : Colors.green))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
