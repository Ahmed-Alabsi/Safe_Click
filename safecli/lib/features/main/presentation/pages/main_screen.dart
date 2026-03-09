import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/settings/presentation/providers/settings_controller.dart';
import 'package:safeclik/features/scan/presentation/controllers/scan_notifier.dart';
import 'package:safeclik/features/profile/presentation/widgets/stats_card.dart';
import 'package:safeclik/features/scan/presentation/pages/result_screen.dart';
import 'dart:io';
import 'dart:async';

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
              const SizedBox(height: 20),
              _buildErrorWidget(),
              const SizedBox(height: 30),
              _buildStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
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
            'حماية ذكية من الروابط الضارة والتصيد الإلكتروني',
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
                  child: ElevatedButton.icon(
                    onPressed: scanState.isScanning
                        ? null
                        : () => _performScan(context),
                    icon: const Icon(Icons.search),
                    label: scanState.isScanning
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                          )
                        : const Text('فحص الرابط'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
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

  Widget _buildErrorWidget() {
    final scanState = ref.watch(scanNotifierProvider);
    if (scanState.lastError == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              scanState.lastError!,
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => ref.read(scanNotifierProvider.notifier).clearError(),
          ),
        ],
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
        icon: Icon(
          Icons.wifi_off_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('لا يوجد اتصال بالإنترنت'),
        content: const Text(
          'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.\n\n'
          'تأكد من:'
          '\n• تفعيل الواي فاي أو البيانات'
          '\n• استقرار الشبكة'
        ),
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

  // التحقق من سرعة الإنترنت
  final isSpeedGood = await _checkInternetSpeed();
  if (!isSpeedGood) {
    if (!context.mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.speed,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('اتصال الإنترنت بطيء'),
        content: const Text(
          'اتصال الإنترنت الحالي بطيء وقد يستغرق الفحص وقتاً أطول من المعتاد.\n\n'
          'هل تريد المتابعة على أي حال؟'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('متابعة على أي حال'),
          ),
        ],
      ),
    );
    
    if (!context.mounted || proceed != true) return;
    
    // عرض مؤشر مع رسالة توضيحية
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('جاري الفحص... قد يستغرق وقتاً أطول بسبب بطء الاتصال')),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // محاولة الفحص مع timeout
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
      final errorMsg = scanState.lastError ?? 'حدث خطأ أثناء الفحص';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تعذر الفحص'),
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
  } on TimeoutException catch (_) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.timer_off,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('انتهت مهلة الفحص'),
        content: const Text(
          'استغرق الفحص وقتاً طويلاً جداً. هذا قد يكون بسبب:\n'
          '• ضعف شديد في الاتصال\n'
          '• مشكلة في الخادم\n'
          '• الرابط غير مستجيب\n\n'
          'يرجى المحاولة مرة أخرى لاحقاً.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خطأ في الفحص'),
        content: Text('حدث خطأ غير متوقع: $e'),
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
