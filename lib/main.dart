import 'package:fatora_pro/pages/accounts_page.dart';
import 'package:fatora_pro/pages/create_invoice_page.dart';
import 'package:fatora_pro/pages/invoices_page.dart';
import 'package:fatora_pro/pages/products_page.dart';
import 'package:fatora_pro/pages/reports_page.dart';
import 'package:fatora_pro/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة تنسيق التواريخ للغة العربية
  await initializeDateFormatting('ar_SA', null);
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppProvider()..loadAllData(), // تحميل البيانات عند بدء التشغيل
      child: const FatoraProApp(),
    ),
  );
}

class FatoraProApp extends StatelessWidget {
  const FatoraProApp({super.key});

  @override
  Widget build(BuildContext context) {
    // اللون الأزرق الأساسي من ملف CSS
    const Color primaryColor = Color(0xFF1e40af);
    const Color primaryDark = Color(0xFF1e3a8a);
    const Color primaryLight = Color(0xFF3b82f6);
    const Color backgroundLight = Color(0xFFeff6ff);

    return MaterialApp(
      title: 'فاتورة برو',
      debugShowCheckedModeBanner: false,
      
      // === إعدادات اللغة العربية و RTL ===
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // === إعدادات الثيم (Material 3) ===
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundLight,
        fontFamily: 'Cairo', // تأكد من إضافة الخط لـ pubspec.yaml إذا أردت استخدامه في واجهة التطبيق أيضاً
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: primaryLight,
          background: backgroundLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: primaryLight.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.blue.shade100, width: 2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor, width: 2.5),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // هذا هو التصميم المأخوذ من header في index.html
    final headerGradient = LinearGradient(
      colors: [
        const Color(0xFF1e40af),
        const Color(0xFF3b82f6),
        const Color(0xFF60a5fa),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          // الهيدر المخصص
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: headerGradient),
            child: const SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'محلات ابو جعفر الرديني',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, offset: Offset(1, 1), color: Colors.black26)],
                    ),
                  ),
                  Text(
                    'لتجارة المواد الغذائية والحلويات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          toolbarHeight: 100, // ارتفاع الهيدر
          bottom: TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: '➕ إنشاء فاتورة', icon: Icon(Icons.add_shopping_cart)),
              Tab(text: '🧾 الفواتير', icon: Icon(Icons.receipt_long)),
              Tab(text: '📦 المنتجات', icon: Icon(Icons.inventory_2)),
              Tab(text: '📊 التقارير', icon: Icon(Icons.bar_chart)),
              Tab(text: '👥 الحسابات والديون', icon: Icon(Icons.people_alt)),
            ],
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Cairo'),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, fontFamily: 'Cairo'),
          ),
        ),
        body: const TabBarView(
          children: [
            CreateInvoicePage(),
            InvoicesPage(),
            ProductsPage(),
            ReportsPage(),
            AccountsPage(),
          ],
        ),
      ),
    );
  }
}
