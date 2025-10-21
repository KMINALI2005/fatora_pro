import 'dart:typed_data';
import 'package:fatora_pro/models/invoice.dart';
import 'package:fatora_pro/utils/formatters.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:number_to_words_arabic/number_to_words_arabic.dart';

class PdfService {
  
  Future<void> printInvoice(Invoice invoice) async {
    final pdfData = await _generatePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'فاتورة_${invoice.customer}_${invoice.id}',
    );
  }

  Future<Uint8List> _generatePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // 1. تحميل الخط العربي
    final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final theme = pw.ThemeData.withFont(base: ttf, bold: ttf,);

    // حساب المجاميع
    final double totalQuantity = invoice.items.fold(0, (sum, item) => sum + item.quantity);
    final double remaining = invoice.remainingBalance;
    final String remainingInWords = NumberToWordsArabic.convert(remaining.toInt());
    
    final String currentTime = Formatters.formatArabicTime(DateTime.now());
    final String invoiceDate = Formatters.formatDate(DateTime.parse(invoice.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30), // هوامش 8mm
        theme: theme,
        build: (pw.Context context) => [
          _buildHeader(),
          _buildInvoiceInfo(invoice, invoiceDate, currentTime),
          _buildItemsTable(invoice),
          _buildQuantitySummary(totalQuantity),
          pw.SizedBox(height: 6),
          _buildSummary(invoice, remaining, remainingInWords),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader() {
    // محاكاة الهيدر في index.html
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 3, color: PdfColors.black),
      ),
      child: pw.Column(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('محلات ابو جعفر الرديني', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22)),
                    pw.Text('لتجارة المواد الغذائية والحلويات', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1, color: PdfColors.black),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('رقم الفاتورة:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('#${invoice.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Divider(height: 2, color: PdfColors.black, thickness: 2),
          pw.Padding(
             padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
             child: pw.Row(
               mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
               children: [
                 pw.Text('07731103122 | 07800379300', textDirection: pw.TextDirection.ltr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                 pw.Container(width: 2, height: 15, color: PdfColors.black),
                 pw.Text('07826342265', textDirection: pw.TextDirection.ltr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
               ]
             )
          ),
          pw.Divider(height: 2, color: PdfColors.black, thickness: 2),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Text('📍 بلدروز - مقابل مطعم - بغداد - داخل القيصرية', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceInfo(Invoice invoice, String date, String time) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6, bottom: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2, color: PdfColors.black),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('الزبون: ${invoice.customer}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('التاريخ: $date | $time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textDirection: pw.TextDirection.ltr),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(Invoice invoice) {
    final headers = ['#', 'المنتج', 'الكمية', 'السعر', 'المبلغ', 'الملاحظات'];
    
    final data = invoice.items.asMap().entries.map((entry) {
      int idx = entry.key;
      InvoiceItem item = entry.value;
      return [
        (idx + 1).toString(),
        item.product,
        Formatters.formatCurrency(item.quantity),
        Formatters.formatCurrency(item.price),
        Formatters.formatCurrency(item.total),
        item.notes,
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(width: 1.5, color: PdfColors.black),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: const pw.TextStyle(fontSize: 9.5),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(3.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(2),
      }
    );
  }
  
  pw.Widget _buildQuantitySummary(double totalQuantity) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border(
          left: pw.BorderSide(width: 1.5, color: PdfColors.black),
          right: pw.BorderSide(width: 1.5, color: PdfColors.black),
          bottom: pw.BorderSide(width: 1.5, color: PdfColors.black),
        )
      ),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Row(
        children: [
          pw.Text('إجمالي الكمية:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
          pw.SizedBox(width: 20),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 2, color: PdfColors.black),
              color: PdfColors.white,
            ),
            child: pw.Text(Formatters.formatCurrency(totalQuantity), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          )
        ]
      )
    );
  }
  
  pw.Widget _buildSummary(Invoice invoice, double remaining, String remainingInWords) {
    
    pw.Widget buildRow(String label, String value, {pw.FontWeight weight = pw.FontWeight.bold, double fontSize = 11}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(value, style: pw.TextStyle(fontWeight: weight, fontSize: fontSize), textDirection: pw.TextDirection.ltr),
            pw.Text(label, style: pw.TextStyle(fontWeight: weight, fontSize: fontSize)),
          ]
        ),
      );
    }
    
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2, color: PdfColors.black),
      ),
      child: pw.Column(
        children: [
          buildRow('إجمالي الفاتورة:', '${Formatters.formatCurrency(invoice.total)} دينار'),
          pw.Divider(height: 1, color: PdfColors.black, thickness: 1),
          buildRow('الحساب السابق:', '${Formatters.formatCurrency(invoice.previousBalance)} دينار'),
          pw.Divider(height: 1, color: PdfColors.black, thickness: 1),
          buildRow('المبلغ الواصل:', '${Formatters.formatCurrency(invoice.payment)} دينار'),
          pw.Container(
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(width: 2, color: PdfColors.black)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Flexible(
                  flex: 3,
                  child: pw.Text(
                    '$remainingInWords دينار عراقي فقط لا غير',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                    textAlign: pw.TextAlign.center
                  ),
                ),
                pw.Flexible(
                  flex: 2,
                  child: pw.Text(
                    '${Formatters.formatCurrency(remaining)} دينار',
                     style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                     textDirection: pw.TextDirection.ltr
                  ),
                ),
                pw.Text('المبلغ المتبقي:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ]
            )
          ),
        ]
      )
    );
  }
}
