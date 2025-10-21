import 'package:fatora_pro/models/product.dart';
import 'package:fatora_pro/providers/app_provider.dart';
import 'package:fatora_pro/services/file_service.dart';
import 'package:fatora_pro/utils/formatters.dart';
import 'package:fatora_pro/widgets/gradient_button.dart';
import 'package:fatora_pro/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _searchController = TextEditingController();
  
  String _searchQuery = '';
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
    _nameController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final price = Formatters.parseDouble(_priceController.text);
      
      context.read<AppProvider>().addOrUpdateProduct(name, price);
      
      _nameController.clear();
      _priceController.clear();
      FocusScope.of(context).unfocus(); // إخفاء الكيبورد
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حفظ المنتج/تحديث السعر'), backgroundColor: Colors.green),
      );
    }
  }

  void _confirmClearAllProducts() {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد المسح'),
        content: Text('هل أنت متأكد من حذف جميع المنتجات؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('إلغاء')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AppProvider>().clearAllProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف جميع المنتجات'), backgroundColor: Colors.green),
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
    return ListView(
      padding: const EdgeInsets.all(12.0),
      children: [
        // 1. إضافة منتج جديد
        _buildAddProductCard(),
        
        // 2. أزرار الإجراءات
        _buildImportExportActions(),

        // 3. البحث
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: '🔍 بحث عن منتج:',
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

        // 4. قائمة المنتجات
        _buildProductsList(),
      ],
    );
  }

  Widget _buildAddProductCard() {
    return SectionCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إضافة منتج جديد (أو تحديث سعره)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '📝 اسم المنتج الجديد:'),
              validator: (value) => value == null || value.isEmpty ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: '💵 سعر المنتج:'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'السعر مطلوب';
                if (Formatters.parseDouble(value) <= 0) return 'السعر يجب أن يكون أكبر من صفر';
                return null;
              },
              onFieldSubmitted: (_) => _saveProduct(), // للإضافة السريعة بـ Enter
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: _saveProduct,
              child: const Text('💾 حفظ المنتج'),
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
            onPressed: () => _fileService.importProducts(context),
            colors: GradientButton.successGradient,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.upload), SizedBox(width: 8), Text('استيراد منتجات')]),
          ),
          GradientButton(
            onPressed: () => _fileService.exportProducts(context),
            colors: GradientButton.primaryGradient,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.download), SizedBox(width: 8), Text('تصدير منتجات')]),
          ),
           GradientButton(
            onPressed: _confirmClearAllProducts,
            colors: GradientButton.dangerGradient,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.delete_forever), SizedBox(width: 8), Text('مسح الكل')]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final filteredProducts = provider.products.where((p) => 
          p.name.toLowerCase().contains(_searchQuery)
        ).toList();
        
        if (filteredProducts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('📦 لا توجد منتجات تطابق البحث', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
          );
        }

        return SectionCard(
          padding: const EdgeInsets.all(0),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return ListTile(
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('السعر: ${Formatters.formatCurrency(product.price)} دينار', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    _confirmDeleteProduct(product);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج: ${product.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('إلغاء')),
          FilledButton(onPressed: (){
              Navigator.of(ctx).pop();
              context.read<AppProvider>().deleteProduct(product.id!);
          }, child: Text('نعم، احذف')),
        ],
      ),
    );
  }
}
