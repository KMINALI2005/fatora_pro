import 'package:intl/intl.dart';

class Formatters {
  // استخدام تنسيق الأرقام الإنجليزية كما في JS
  static final NumberFormat _currencyFormat =
      NumberFormat("#,##0", "en_US");
  
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd', 'en_US');
  
  static final DateFormat _arabicDateFormat = DateFormat('dd/MM/yyyy', 'ar_SA');
  
  static final DateFormat _timeFormat = DateFormat('h:mm a', 'ar_SA');

  static String formatCurrency(num number) {
    return _currencyFormat.format(number);
  }
  
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  static String formatArabicDate(DateTime date) {
    return _arabicDateFormat.format(date);
  }
  
  static String formatArabicTime(DateTime date) {
    return _timeFormat.format(date);
  }
  
  static double parseDouble(String value) {
    // إزالة الفواصل والتعامل مع الأرقام العربية
    String englishNumbers = value
        .replaceAll(',', '')
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
    return double.tryParse(englishNumbers) ?? 0.0;
  }
}
