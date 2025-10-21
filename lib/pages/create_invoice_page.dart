import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fatora_pro/models/account.dart';
import 'package:fatora_pro/models/invoice.dart';
import 'package:fatora_pro/models/invoice_item.dart';
import 'package:fatora_pro/models/product.dart';
import 'package:fatora_pro/providers/app_provider.dart';
import 'package:fatora_pro/utils/formatters.dart';
import 'package:fatora_pro/widgets/gradient_button.dart';
import 'package:fatora_pro/widgets/section_card.dart';
import 'package:fatora_pro/widgets/total_display_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class CreateInvoicePage extends StatefulWidget {
  // لاستقبال فاتورة للتعديل (اختياري)
  final Invoice? invoiceToEdit;
  const CreateInvoicePage({Key? key, this.invoiceToEdit}) : super(key: key);

  @override
  _CreateInvoicePageState createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  // Controllers للنموذج
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _previousBalanceController = TextEditingController(text: '0');
  final _paymentAmountController = TextEditingController(text: '0');

  // Controllers للمنتجات
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _itemNotesController = TextEditingController();

  // حالة الفاتورة الحالية
  List<InvoiceItem> _currentItems = [];
  double _currentTotal = 0.0;
  double _lineTotal = 0.0;
  double _remainingAmount = 0.0;
  
  bool _isEditingItem = false;
  int _editingItemIndex = -1;
  bool _isEditingInvoice = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoiceToEdit != null) {
      _loadInvoiceForEditing(widget.invoiceToEdit!);
    } else {
      _invoiceDateController.text = Formatters.formatDate(DateTime.now());
    }
    
    // ربط المستمعات لحساب الإجماليات
    _quantityController.addListener(_updateLineTotal);
    _priceController.addListener(_updateLineTotal);
    _previousBalanceController.addListener(_updateFinalTotals);
    _paymentAmountController.addListener(_updateFinalTotals);
  }
  
  void _loadInvoiceForEditing(Invoice inv) {
    setState(() {
      _isEditingInvoice = true;
      _customerNameController.text = inv.customer;
      _invoiceDateController.text = inv.date;
      _previousBalanceController.text = Formatters.formatCurrency(inv.previousBalance);
      _paymentAmountController.text = Formatters.formatCurrency(inv.payment);
      _currentItems = List.from(inv.items);
      _updateFinalTotals();
    });
  }

  @override
  void dispose() {
    // تنظيف Controllers
    _customerNameController.dispose();
    _invoiceDateController.dispose();
    _previousBalanceController.dispose();
    _paymentAmountController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _itemNotesController.dispose();
    super.dispose();
  }

  void _updateLineTotal() {
    final double q = Formatters.parseDouble(_quantityController.text);
    final double p = Formatters.parseDouble(_priceController.text);
    setState(() {
      _lineTotal = q * p;
    });
  }

  void _updateFinalTotals() {
    final double prevBal = Formatters.parseDouble(_previousBalanceController.text);
    final double payment = Formatters.parseDouble(_paymentAmountController.text);
    
    _currentTotal = _currentItems.fold(0.0, (sum, item) => sum + item.total);
    
    setState(() {
      _remainingAmount = (_currentTotal + prevBal) - payment;
    });
  }
  
  void _handleItemAddOrUpdate() {
    final String productName = _productNameController.text.trim();
    final double quantity = Formatters.parseDouble(_quantityController.text);
    final double price = Formatters.parseDouble(_priceController.text);
    final String notes = _itemNotesController.text.trim();

    if (productName.isEmpty || quantity <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم وكمية وسعر صحيح'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // إضافة المنتج لقاعدة البيانات (للحفظ التلقائي للسعر)
    context.read<AppProvider>().addOrUpdateProduct(productName, price);

    final item = InvoiceItem(
      product: productName,
      quantity: quantity,
      price: price,
      total: quantity * price,
      notes: notes,
    );

    setState(() {
      if (_isEditingItem) {
        _currentItems[_editingItemIndex] = item;
      } else {
        _currentItems.add(item);
      }
      _resetItemForm();
      _updateFinalTotals();
    });
  }
  
  void _resetItemForm() {
    _productNameController.clear();
    _quantityController.text = '1';
    _priceController.clear();
    _itemNotesController.clear();
    setState(() {
      _lineTotal = 0.0;
      _isEditingItem = false;
      _editingItemIndex = -1;
    });
    FocusScope.of(context).requestFocus(FocusNode()); // إخفاء الكيبورد
  }

  void _editItem(int index) {
    final item = _currentItems[index];
    setState(() {
      _productNameController.text = item.product;
      _quantityController.text = Formatters.formatCurrency(item.quantity);
      _priceController.text = Formatters.formatCurrency(item.price);
      _itemNotesController.text = item.notes;
      _isEditingItem = true;
      _editingItemIndex = index;
      _updateLineTotal();
    });
    // TODO: تمرير الصفحة للأعلى
  }
  
  void _removeItem(int index) {
    setState(() {
      _currentItems.removeAt(index);
      _updateFinalTotals();
    });
  }

  void _clearInvoice() {
    setState(() {
      _customerNameController.clear();
      _invoiceDateController.text = Formatters.formatDate(DateTime.now());
      _previousBalanceController.text = '0';
      _paymentAmountController.text = '0';
      _currentItems.clear();
      _resetItemForm();
      _updateFinalTotals();
      _isEditingInvoice = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم مسح الفاتورة'), backgroundColor: Colors.orange),
    );
  }
  
  void _confirmClearInvoice() {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد المسح'),
        content: Text('هل أنت متأكد من مسح جميع حقول الفاتورة الحالية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('إلغاء')),
          FilledButton(onPressed: (){
             Navigator.of(ctx).pop();
             _clearInvoice();
          }, child: Text('نعم، امسح')),
        ],
      ),
    );
  }
  
  Future<void> _saveOrUpdateInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_currentItems.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حفظ فاتورة فارغة'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final invoice = Invoice(
      id: _isEditingInvoice ? widget.invoiceToEdit!.id : null,
      customer: _customerNameController.text.trim(),
      date: _invoiceDateController.text,
      items: _currentItems,
      total: _currentTotal,
      previousBalance: Formatters.parseDouble(_previousBalanceController.text),
      payment: Formatters.parseDouble(_paymentAmountController.text),
      printHistory: _isEditingInvoice ? widget.invoiceToEdit!.printHistory : {},
    );
    
    final provider = context.read<AppProvider>();
    
    try {
      if (_isEditingInvoice) {
        await provider.updateInvoice(invoice);
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم تحديث الفاتورة بنجاح!'), backgroundColor: Colors.green),
        );
      } else {
        await provider.saveInvoice(invoice);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حفظ الفاتورة بنجاح!'), backgroundColor: Colors.green),
        );
      }
      _clearInvoice();
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _shareInvoice() {
     if (_currentItems.isEmpty) return;
     
     String text = "فاتورة: *${_customerNameController.text}*\n";
     text += "التاريخ: ${_invoiceDateController.text}\n";
     text += "------------------------------------\n";
     
     for (var item in _currentItems) {
       text += "${item.product} (${Formatters.formatCurrency(item.quantity)} x ${Formatters.formatCurrency(item.price)}) = *${Formatters.formatCurrency(item.total)}*\n";
       if(item.notes.isNotEmpty) {
         text += "   - _ملاحظة: ${item.notes}_\n";
       }
     }
     
     text += "------------------------------------\n";
     text += "المجموع: ${Formatters.formatCurrency(_currentTotal)}\n";
     text += "حساب سابق: ${Formatters.formatCurrency(Formatters.parseDouble(_previousBalanceController.text))}\n";
     text += "الواصل: ${Formatters.formatCurrency(Formatters.parseDouble(_paymentAmountController.text))}\n";
     text += "*المتبقي: ${Formatters.formatCurrency(_remainingAmount)}*\n";
     
     Share.share(text);
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. معلومات الزبون
            _buildCustomerCard(),
            
            // 2. إضافة منتج
            _buildAddItemCard(),
            
            // 3. جدول المنتجات
            if (_currentItems.isNotEmpty) _buildItemsList(),
            
            // 4. الملخص النهائي
            _buildSummaryCard(),
            
            // 5. أزرار الإجراءات
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return SectionCard(
      child: Column(
        children: [
          // اقتراحات الزبائن
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return TypeAheadFormField<Account>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: '🙋‍♂️ اسم الزبون:',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                suggestionsCallback: (pattern) {
                  if (pattern.isEmpty) return [];
                  return provider.accounts.where((acc) =>
                      acc.customerName.toLowerCase().contains(pattern.toLowerCase()));
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion.customerName),
                    subtitle: Text('المتبقي: ${Formatters.formatCurrency(suggestion.finalBalance)} دينار'),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  _customerNameController.text = suggestion.customerName;
                  // جلب الرصيد السابق تلقائياً
                  if (!_isEditingInvoice) {
                     _previousBalanceController.text = Formatters.formatCurrency(suggestion.finalBalance > 0 ? suggestion.finalBalance : 0);
                     _updateFinalTotals();
                  }
                },
                validator: (value) => value == null || value.isEmpty ? 'اسم الزبون مطلوب' : null,
              );
            },
          ),
          const SizedBox(height: 16),
          // حقل التاريخ
          TextFormField(
            controller: _invoiceDateController,
            decoration: const InputDecoration(
              labelText: '📅 تاريخ الفاتورة:',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                _invoiceDateController.text = Formatters.formatDate(picked);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemCard() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // اقتراحات المنتجات
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return TypeAheadFormField<Product>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _productNameController,
                  decoration: const InputDecoration(
                    labelText: '🔍 اسم المنتج:',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                suggestionsCallback: (pattern) {
                   if (pattern.isEmpty) return [];
                  return provider.products.where((p) =>
                      p.name.toLowerCase().contains(pattern.toLowerCase()));
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion.name),
                    trailing: Text('${Formatters.formatCurrency(suggestion.price)} د', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  _productNameController.text = suggestion.name;
                  _priceController.text = Formatters.formatCurrency(suggestion.price);
                  _updateLineTotal();
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: '📊 الكمية:'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: '💵 السعر:'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TotalDisplayBox(text: Formatters.formatCurrency(_lineTotal)),
          const SizedBox(height: 16),
           TextFormField(
            controller: _itemNotesController,
            decoration: const InputDecoration(
              labelText: '📝 ملاحظات المنتج (اختياري):',
              prefixIcon: Icon(Icons.note_alt),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            onPressed: _handleItemAddOrUpdate,
            colors: _isEditingItem ? GradientButton.warningGradient : GradientButton.primaryGradient,
            child: Text(_isEditingItem ? '✏️ تحديث المنتج' : '➕ إضافة المنتج للفاتورة'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    // استخدام DataTable لمحاكاة الجدول في HTML
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('المنتج')),
            DataColumn(label: Text('الكمية')),
            DataColumn(label: Text('السعر')),
            DataColumn(label: Text('المجموع')),
            DataColumn(label: Text('ملاحظات')),
            DataColumn(label: Text('تعديل')),
            DataColumn(label: Text('حذف')),
          ],
          rows: _currentItems.asMap().entries.map((entry) {
            int idx = entry.key;
            InvoiceItem item = entry.value;
            return DataRow(
              cells: [
                DataCell(Text((idx + 1).toString())),
                DataCell(Text(item.product)),
                DataCell(Text(Formatters.formatCurrency(item.quantity))),
                DataCell(Text(Formatters.formatCurrency(item.price))),
                DataCell(Text(Formatters.formatCurrency(item.total), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
                DataCell(Text(item.notes.isEmpty ? '-' : item.notes)),
                DataCell(IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _editItem(idx))),
                DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeItem(idx))),
              ]
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    final double totalQuantity = _currentItems.fold(0.0, (sum, item) => sum + item.quantity);
    
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('💵 إجمالي الفاتورة الحالية:', style: TextStyle(fontWeight: FontWeight.w600)),
                     TotalDisplayBox(text: '${Formatters.formatCurrency(_currentTotal)} دينار'),
                   ],
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('📦 إجمالي الكمية:', style: TextStyle(fontWeight: FontWeight.w600)),
                     TotalDisplayBox(text: Formatters.formatCurrency(totalQuantity)),
                   ],
                 ),
               ),
             ],
           ),
           const SizedBox(height: 16),
           Row(
             children: [
                Expanded(
                  child: TextFormField(
                    controller: _previousBalanceController,
                    decoration: const InputDecoration(labelText: '📋 الحساب السابق:'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _paymentAmountController,
                    decoration: const InputDecoration(labelText: '💰 المبلغ الواصل:'),
                    keyboardType: TextInputType.number,
                  ),
                ),
             ],
           ),
           const SizedBox(height: 24),
           const Text('💳 المبلغ المتبقي النهائي:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
           TotalDisplayBox(
             text: '${Formatters.formatCurrency(_remainingAmount)} دينار',
             borderColor: Colors.red.shade700,
             backgroundColor: Colors.red.shade50,
             textColor: Colors.red.shade900,
             fontSize: 24,
           ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          GradientButton(
            onPressed: _saveOrUpdateInvoice,
            minWidth: 180,
            child: Text(_isEditingInvoice ? '✏️ تحديث الفاتورة' : '💾 حفظ الفاتورة'),
          ),
          GradientButton(
            onPressed: _shareInvoice,
            colors: const [Color(0xFF1e3a8a), Color(0xFF3b82f6)], // لون مختلف
            minWidth: 140,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share, size: 20),
                SizedBox(width: 8),
                Text('مشاركة'),
              ],
            ),
          ),
          GradientButton(
            onPressed: _confirmClearInvoice,
            colors: GradientButton.dangerGradient,
            minWidth: 140,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_sweep, size: 20),
                SizedBox(width: 8),
                Text('مسح الكل'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
