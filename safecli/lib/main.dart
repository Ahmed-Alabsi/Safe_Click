// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; 
import 'package:safeclik/features/auth/presentation/pages/welcome_screen.dart';
import 'package:safeclik/core/di/di.dart';
import 'package:safeclik/core/utils/notification_service.dart';
import 'package:safeclik/core/theme/app_theme.dart';
import 'package:safeclik/core/network/api_client.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_controller.dart';
import 'package:safeclik/features/settings/presentation/providers/settings_controller.dart';
import 'package:safeclik/features/scan/presentation/controllers/scan_notifier.dart';
import 'package:safeclik/features/scan/data/models/scan_result.dart';
import 'package:safeclik/features/main/presentation/pages/splash_screen.dart';
import 'package:safeclik/features/auth/presentation/pages/login_screen.dart';
import 'package:safeclik/features/auth/presentation/pages/register_screen.dart';
import 'package:safeclik/features/main/presentation/pages/home_screen.dart';
import 'package:safeclik/features/main/presentation/pages/main_screen.dart';
import 'package:safeclik/features/scan/presentation/pages/result_screen.dart';
import 'package:safeclik/features/scan/presentation/pages/history_screen.dart';
import 'package:safeclik/features/profile/presentation/pages/profile_screen.dart';
import 'package:safeclik/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:safeclik/features/report/presentation/pages/report_screen.dart';
import 'package:safeclik/features/settings/presentation/pages/settings_screen.dart';
import 'package:safeclik/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ دالة معالجة الإشعارات في الخلفية (يجب أن تكون في أعلى مستوى)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // تهيئة Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('📱 [خلفية] إشعار: ${message.notification?.title}');
  print('📱 البيانات: ${message.data}');
  
  // هنا يمكنك حفظ الإشعار في قاعدة البيانات المحلية
  // أو تحديث حالة التطبيق
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تحميل المتغيرات البيئية
  await dotenv.load(fileName: '.env');

  // 2. تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. إعداد معالج الإشعارات في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. تهيئة الـ DI (حقن التبعيات)
  await initDI();

  // 5. تهيئة ApiClient
  await ApiClient.initialize();

  // 6. تهيئة NotificationService (هذا سيقوم بكل شيء)
  await sl<NotificationService>().initialize();

  // ✅ 7. التحقق من حالة الإشعارات والروابط العميقة المحفوظة وتطبيقها
  await _setupNotificationAndDeepLinksSettings();

  // 8. تشغيل التطبيق
  runApp(const ProviderScope(child: MyApp()));
}

// ✅ دالة محدثة لإعداد الإشعارات والروابط العميقة حسب الإعدادات المحفوظة
Future<void> _setupNotificationAndDeepLinksSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications') ?? true;
    final autoScanEnabled = prefs.getBool('autoScan') ?? true;
    // ✅ deepLinks مرتبط بـ autoScan وليس notifications
    final deepLinksEnabled = prefs.getBool('deepLinks') ?? autoScanEnabled;
    
    final notificationService = sl<NotificationService>();
    
    // إعداد الإشعارات
    if (notificationsEnabled) {
      // إذا كانت الإشعارات مفعلة في الإعدادات، اشترك في المواضيع
      await notificationService.subscribeToTopic('all_users');
      await notificationService.subscribeToTopic('security_alerts');
      print('✅ تم الاشتراك في الإشعارات حسب الإعدادات');
    } else {
      // إذا كانت الإشعارات معطلة، تأكد من إلغاء الاشتراك
      await notificationService.unsubscribeFromTopic('all_users');
      await notificationService.unsubscribeFromTopic('security_alerts');
      print('🔕 الإشعارات معطلة حسب الإعدادات');
    }
    
    // ✅ إعداد الروابط العميقة (مرتبطة بـ autoScan)
    if (deepLinksEnabled) {
      print('🔗 الروابط العميقة مفعلة (مرتبطة بالفحص التلقائي)');
    } else {
      print('🔗 الروابط العميقة معطلة (الفحص التلقائي معطل)');
    }
    
  } catch (e) {
    print('❌ خطأ في إعداد الإعدادات: $e');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingLink;
  bool _processingDeepLink = false;
  
  // للإشعارات
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  
  // ✅ متغير للتحكم في مدة ظهور Splash Screen
  bool _showSplash = true;

  Future<void> _initializeApp() async {
    // ننتظر انتهاء الأنيميشن (2 ثانية) بالإضافة إلى أي بيانات أساسية إضافية إن وجدت
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      // يمكن إضافة _loadInitialData() هنا
    ]);

    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _listenToNotifications();
    
    _initializeApp();
  }

  // ✅ الاستماع للإشعارات الواردة
  void _listenToNotifications() {
    _notificationSubscription = sl<NotificationService>().onFirebaseMessageReceived.listen((message) {
      debugPrint('📱 تم استقبال إشعار عبر الـ Stream');
      
      // التحقق من حالة الإشعارات في الإعدادات قبل عرض الإشعار
      final settings = ref.read(settingsProvider).value;
      if (settings?.notifications ?? true) {
        // فقط إذا كانت الإشعارات مفعلة نقوم بمعالجتها
        _handleNotificationNavigation(message);
      }
    });
  }

  // ✅ التعامل مع التنقل بناءً على الإشعار
  void _handleNotificationNavigation(RemoteMessage message) {
    // التحقق من وجود بيانات في الإشعار
    final data = message.data;
    if (data.containsKey('screen')) {
      final screen = data['screen'];
      final id = data['id'];
      
      debugPrint('📱 التوجه للشاشة: $screen بالمعرف: $id');
      
      // هنا يمكنك توجيه المستخدم للشاشة المناسبة
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (screen == 'result' && id != null) {
            // يمكنك هنا جلب نتيجة الفحص من id والتنقل إليها
            // Navigator.pushNamed(context, '/result', arguments: id);
          } else if (screen == 'report') {
            // Navigator.pushNamed(context, '/report');
          }
        });
      }
    }
  }

  Future<void> _initDeepLinks() async {
    try {
      // ✅ التحقق من إعدادات الروابط العميقة قبل البدء (مرتبطة بـ autoScan)
      final settings = ref.read(settingsProvider).value;
      final deepLinksEnabled = settings?.deepLinks ?? settings?.autoScan ?? true;
      
      if (!deepLinksEnabled) {
        debugPrint('🔗 الروابط العميقة معطلة حسب الإعدادات - لن يتم الاستماع للروابط');
        return;  // لا نستمع للروابط إذا كانت معطلة
      }
      
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        debugPrint('📱 تم فتح التطبيق عبر رابط: $initialLink');
        _pendingLink = initialLink.toString();
      }

      _linkSubscription = _appLinks.allUriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          debugPrint('📱 تم استقبال رابط: $uri');
          
          // ✅ التحقق مرة أخرى عند وصول الرابط (للتأكد)
          final currentSettings = ref.read(settingsProvider).value;
          if (!(currentSettings?.deepLinks ?? currentSettings?.autoScan ?? true)) {
            debugPrint('🔗 تم تجاهل الرابط لأن الروابط العميقة معطلة');
            return;
          }
          
          _pendingLink = uri.toString();
          if (mounted) setState(() {});
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في الروابط: $e');
    }
  }

  // ✅ تحديث دالة معالجة الرابط المعلق للتحقق من إعدادات الروابط العميقة
  Future<void> _handlePendingLink(BuildContext context) async {
    if (_pendingLink == null || _processingDeepLink) return;

    // ✅ التحقق من إعدادات الروابط العميقة (مرتبطة بـ autoScan)
    final settings = ref.read(settingsProvider).value;
    if (!(settings?.deepLinks ?? settings?.autoScan ?? true)) {
      debugPrint('🔗 تم تجاهل الرابط المعلق لأن الروابط العميقة معطلة');
      _pendingLink = null;
      return;
    }

    final link = _pendingLink!;
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    _processingDeepLink = true;
    _pendingLink = null;

    if (!context.mounted) {
      _processingDeepLink = false;
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ref.read(scanNotifierProvider.notifier).scanLink(link);

    if (!context.mounted) {
      _processingDeepLink = false;
      return;
    }

    Navigator.pop(context);

    if (result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(scanResult: result),
        ),
      );
    } else {
      final errorMsg = ref.read(scanNotifierProvider).lastError ?? 'فشل فحص الرابط';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    _processingDeepLink = false;
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsyncValue = ref.watch(settingsProvider);
    final isDarkMode = settingsAsyncValue.value?.darkMode ?? false;

    return MaterialApp(
      title: 'Safe Click',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Consumer(
  builder: (context, ref, child) {
    final authState = ref.watch(authProvider);

    if (_showSplash) {
      return const SplashScreen();
    }

    if (authState.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState.isAuthenticated || authState.isGuest) {
      if (_pendingLink != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handlePendingLink(context);
        });
      }
      return const HomeScreen();
    } else {
      return const WelcomeScreen();
    }
  },
),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/main': (context) => const MainScreen(),
        '/history': (context) => const HistoryScreen(),
        '/report': (context) => const ReportScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/result') {
          final scanResult = settings.arguments as ScanResult?;
          if (scanResult == null) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('خطأ')),
                body: const Center(child: Text('تعذر تحميل نتيجة الفحص')),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (context) => ResultScreen(scanResult: scanResult),
          );
        }
        return null;
      },
    );
  }
}