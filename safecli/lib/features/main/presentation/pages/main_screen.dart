import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/settings/presentation/providers/settings_controller.dart';
import 'package:safeclik/features/scan/presentation/controllers/scan_notifier.dart';
import 'package:safeclik/features/profile/presentation/widgets/stats_card.dart';
import 'package:safeclik/features/scan/presentation/pages/result_screen.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_controller.dart';
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with TickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  final FocusNode _linkFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _linkController.dispose();
    _linkFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> _checkInternetSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      stopwatch.stop();
      // إذا استغرق الرد أكثر من 2 ثانية، نعتبر النت بطيء
      return stopwatch.elapsedMilliseconds < 4000;
    } catch (_) {
      return false;
    }
  }

  /// دالة لمعالجة أخطاء السيرفر وإظهار رسائل مناسبة
  String _getUserFriendlyErrorMessage(dynamic error, String? lastError) {
    // إذا كان هناك خطأ محدد من الـ API
    if (lastError != null && lastError.isNotEmpty) {
      // قائمة بالأخطاء التي يمكن عرضها كما هي
      final safeErrors = [
        'الرابط غير صالح',
        'الرابط لا يمكن الوصول إليه',
        'تم حظر هذا الموقع',
        'تم الإبلاغ عن هذا الرابط كضار',
        'الرجاء تسجيل الدخول أولاً',
      ];
      
      // إذا كان الخطأ من القائمة الآمنة، نعرضه كما هو
      for (final safeError in safeErrors) {
        if (lastError.contains(safeError)) {
          return lastError;
        }
      }
    }
    
    // التحقق من أنواع الأخطاء المعروفة
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'مشكلة في الاتصال بالسيرفر، يرجى المحاولة لاحقاً';
      }
      
      if (error.type == DioExceptionType.connectionError) {
        return 'تعذر الاتصال بالسيرفر، تأكد من اتصالك بالإنترنت';
      }
      
      if (error.response?.statusCode != null) {
        final statusCode = error.response!.statusCode!;
        
        // أخطاء السيرفر (5xx)
        if (statusCode >= 500) {
          return 'مشكلة في السيرفر، يرجى المحاولة لاحقاً';
        }
        
        // أخطاء المصادقة (401, 403)
        if (statusCode == 401 || statusCode == 403) {
          return 'مشكلة في صلاحية الدخول، يرجى تسجيل الدخول مرة أخرى';
        }
        
        // أخطاء أخرى (4xx)
        if (statusCode >= 400) {
          return 'مشكلة في الطلب، يرجى التحقق من الرابط والمحاولة مرة أخرى';
        }
      }
    }
    
    // إذا كان الخطأ يتعلق بالشبكة
    if (error is SocketException) {
      return 'مشكلة في الاتصال بالإنترنت، تحقق من شبكتك';
    }
    
    if (error is TimeoutException) {
      return 'انتهت مهلة الاتصال بالسيرفر، يرجى المحاولة لاحقاً';
    }
    
    // إذا كان الخطأ يتعلق بالسيرفر من النص
    if (error.toString().contains('server') || 
        error.toString().contains('Server') ||
        error.toString().contains('500') ||
        error.toString().contains('503')) {
      return 'مشكلة في السيرفر، يرجى المحاولة لاحقاً';
    }
    
    // رسالة افتراضية عامة
    return 'حدثت مشكلة في السيرفر، يرجى المحاولة لاحقاً';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildScanCard(),
              const SizedBox(height: 30),
              _buildStats(),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.login_rounded, color: Colors.orange),
          SizedBox(width: 12),
          Text('انتهت الفحوصات المجانية'),
        ],
      ),
      content: const Text(
        'لقد استخدمت جميع الفحوصات المجانية المتاحة (3 فحوصات).\n\n'
        'قم بتسجيل الدخول أو إنشاء حساب جديد للاستمرار.'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('تسجيل الدخول'),
        ),
      ],
    ),
  );
}

  Widget _buildHeader() {
  final authState = ref.watch(authProvider);
  final isGuest = authState.isGuest;
  final remainingScans = isGuest ? authState.remainingGuestScans : 0; // ✅ استخدام getter مباشرة
  
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isGuest
            ? [
                Colors.orange,
                Colors.orange.withValues(alpha: 0.8),
                Colors.amber,
              ]
            : [
                Theme.of(context).colorScheme.tertiary,
                Theme.of(context).colorScheme.tertiaryContainer,
              ],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor,
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        if (isGuest)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'متبقي $remainingScans/3 فحوصات',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.security_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.onTertiary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Safe Click',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onTertiary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          isGuest
              ? 'مرحباً بك كزائر - استمتع بفحص 3 روابط مجاناً'
              : 'حماية ذكية من الروابط الضارة والتصيد الإلكتروني',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

  Widget _buildScanCard() {
    final settingsAsyncValue = ref.watch(settingsProvider);
    final autoScan = settingsAsyncValue.value?.autoScan ?? false;
    final scanState = ref.watch(scanNotifierProvider);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'فحص رابط جديد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _linkController,
              focusNode: _linkFocusNode,
              decoration: InputDecoration(
                hintText: 'https://example.com',
                labelText: 'أدخل الرابط هنا',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                prefixIcon: Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _linkController.clear(),
                ),
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: scanState.isScanning ? null : () => _performScan(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: scanState.isScanning
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'فحص الرابط',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
            if (autoScan)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'المسح التلقائي مفعل',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final scanState = ref.watch(scanNotifierProvider);
    final h = scanState.scanHistory;
    final total = h.length;
    final dangerous = h.where((s) => s.safe == false).length;
    return StatsCard(
      scannedCount: total.toString(),
      maliciousCount: dangerous.toString(),
      blockedCount: dangerous.toString(),
    );
  }

  Future<void> _performScan(BuildContext context) async {
  final authState = ref.read(authProvider);
  final authNotifier = ref.read(authProvider.notifier);
  
  // التحقق من الزائر
  if (authState.isGuest) {
    if (!authNotifier.canGuestScan()) {
      _showLoginDialog();
      return;
    }
  }

  if (ref.read(scanNotifierProvider).isScanning) return;

  if (_linkController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('يرجى إدخال رابط لفحصه'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  // التحقق من الاتصال بالإنترنت
  final hasInternet = await _checkInternetConnectivity();
  if (!hasInternet) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.wifi_off_rounded, color: Theme.of(context).colorScheme.error, size: 48),
        title: const Text('لا يوجد اتصال بالإنترنت'),
        content: const Text('يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
    return;
  }

  try {
    final result = await ref
        .read(scanNotifierProvider.notifier)
        .scanLink(_linkController.text.trim())
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('استغرق الفحص وقتاً طويلاً');
          },
        );

    if (!context.mounted) return;

    if (result != null) {
      // زيادة عدد فحوصات الزائر فقط بعد الفحص الناجح
      if (authState.isGuest) {
        await authNotifier.incrementGuestScanCount();
      }
      
      _linkController.clear();
      _linkFocusNode.unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(scanResult: result),
        ),
      );
    } else {
      final scanState = ref.read(scanNotifierProvider);
      final errorMsg = _getUserFriendlyErrorMessage(null, scanState.lastError);
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('فشل الفحص'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    final errorMsg = _getUserFriendlyErrorMessage(e, null);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مشكلة في السيرفر'),
        content: Text(errorMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}

  void shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة ميزة المشاركة قريباً'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}