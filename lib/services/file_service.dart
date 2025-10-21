import 'dart:convert';
import 'dart:io';
import 'package:fatora_pro/models/invoice.dart';
import 'package:fatora_pro/models/product.dart';
import 'package:fatora_pro/providers/app_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class FileService {
  final AppProvider provider;
  FileService(this.provider);

  // === التصدير ===

  Future<void> exportProducts(BuildContext context) async {
    final products = provider.products;
    if (products.isEmpty) {
      _showSnackBar(context, 'لا توجد منتجات لتصديرها.');
      return;
    }
    final data = {
      'products': products.map((p) => p.toMap()).toList(),
    };
    await _saveAndShareFile(context, 'products_backup.json', data);
  }
  
  Future<void> exportInvoices(BuildContext context) async {
    // يجب علينا جلب الفواتير من قاعدة البيانات مباشرة لضمان عدم فقدان أي بيانات
    await provider.loadAllData();
    final invoices = provider.invoices;
    
    if (invoices.isEmpty) {
      _showSnackBar(context, 'لا توجد فواتير لتصديرها.');
      return;
    }
    final data = {
      'invoices': invoices.map((i) => i.toMap()).toList(),
    };
    await _saveAndShareFile(context, 'invoices_backup.json', data);
  }

  Future<void> _saveAndShareFile(BuildContext context, String fileName, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      
      // طلب إذن التخزين (للأندرويد القديم)
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ملف النسخ الاحتياطي ($fileName)',
      );
    } catch (e) {
      _showSnackBar(context, 'فشل تصدير الملف: $e');
    }
  }

  // === الاستيراد ===

  Future<void> importProducts(BuildContext context) async {
    try {
      final file = await _pickJsonFile();
      if (file == null) return; // ألغى المستخدم الاختيار

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      
      if (data['products'] == null || data['products'] is! List) {
         _showSnackBar(context, 'ملف غير صالح. لم يتم العثور على قائمة "products".');
         return;
      }
      
      final products = (data['products'] as List)
          .map((p) => Product.fromMap(p..remove('id'))) // إزالة ID لإنشاء واحد جديد
          .toList();
          
      if (await _confirmImport(context, 'منتجات', products.length)) {
        await provider.clearAllProducts();
        await provider.bulkAddProducts(products);
        _showSnackBar(context, 'تم استيراد ${products.length} منتج بنجاح.');
      }
      
    } catch (e) {
      _showSnackBar(context, 'فشل استيراد الملف: $e');
    }
  }
  
  Future<void> importInvoices(BuildContext context) async {
    try {
      final file = await _pickJsonFile();
      if (file == null) return;

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      
      if (data['invoices'] == null || data['invoices'] is! List) {
         _showSnackBar(context, 'ملف غير صالح. لم يتم العثور على قائمة "invoices".');
         return;
      }
      
      final invoices = (data['invoices'] as List)
          .map((i) => Invoice.fromMap(i..remove('id')))
          .toList();
          
      if (await _confirmImport(context, 'فواتير', invoices.length)) {
        await provider.clearAllInvoices();
        await provider.bulkAddInvoices(invoices);
        _showSnackBar(context, 'تم استيراد ${invoices.length} فاتورة بنجاح.');
      }
      
    } catch (e) {
      _showSnackBar(context, 'فشل استيراد الملف: $e');
    }
  }
  
  Future<File?> _pickJsonFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
  
  Future<bool> _confirmImport(BuildContext context, String type, int count) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الاستيراد'),
        content: Text('سيتم مسح جميع ($type) الحالية واستبدالها بـ $count عنصر جديد. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('نعم، استورد')),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
