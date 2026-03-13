import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safeclik/features/main/presentation/pages/main_screen.dart';
import 'package:safeclik/features/scan/presentation/pages/history_screen.dart';
import 'package:safeclik/features/report/presentation/pages/report_screen.dart';
import 'package:safeclik/features/profile/presentation/pages/profile_screen.dart';
import 'package:safeclik/features/settings/presentation/pages/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2; // نبدأ من الصفحة الرئيسية (الوسط)
  final List<Widget> _screens = const [
    SettingsScreen(), // 0 - اليمين (سيتم إعادة الترتيب)
    ProfileScreen(),  // 1
    MainScreen(),     // 2 - المنتصف (الرئيسية)
    HistoryScreen(),  // 3
    ReportScreen(),   // 4 - اليسار
  ];

  final List<String> _titles = [
    'الإعدادات',
    'الملف الشخصي',
    'الرئيسية',
    'السجل',
    'الإبلاغ',
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          centerTitle: true,
          actions: _buildAppBarActions(),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBeautifulCenterNavigationBar(),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (_currentIndex == 2) // إذا كنا في الصفحة الرئيسية
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: _showScanOptions,
          tooltip: 'مسح QR',
        ),
    ];
  }

  // ✅ شريط تنقل بوسط بارز وتصميم أنيق
  Widget _buildBeautifulCenterNavigationBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 70, // تصغير ارتفاع الشريط
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // الجهة اليسرى (إعدادات + ملف شخصي)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'الإعدادات',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.person_outlined,
                  activeIcon: Icons.person_rounded,
                  label: 'الملف',
                  index: 1,
                ),
              ],
            ),
          ),

          // زر الرئيسية في المنتصف (بارز)
          GestureDetector(
            onTap: () => setState(() => _currentIndex = 2),
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(bottom: 10), // يظهر للأعلى
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                _currentIndex == 2 ? Icons.home_rounded : Icons.home_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          // الجهة اليمنى (سجل + إبلاغ)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'السجل',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.report_outlined,
                  activeIcon: Icons.report,
                  label: 'الإبلاغ',
                  index: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ عنصر تنقل جانبي
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 2) { // إذا لم نكن في الصفحة الرئيسية
      setState(() {
        _currentIndex = 2; // نعود للصفحة الرئيسية
      });
      return false;
    }
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الخروج'),
            content: const Text('هل تريد الخروج من التطبيق؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('خروج'),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختيار طريقة الفحص',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
              ),
              title: const Text('إدخال رابط'),
              subtitle: const Text('لصق رابط لفحصه'),
              onTap: () {
                Navigator.pop(context);
                // التركيز على حقل الإدخال في الصفحة الرئيسية
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code, color: Theme.of(context).colorScheme.primary),
              ),
              title: const Text('مسح QR Code'),
              subtitle: const Text('استخدم الكاميرا لمسح الرمز'),
              onTap: () {
                Navigator.pop(context);
                _showQRScanner();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة ميزة مسح QR Code قريباً'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}