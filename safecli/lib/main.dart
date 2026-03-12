// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; 

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

  // 7. تشغيل التطبيق
  runApp(const ProviderScope(child: MyApp()));
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

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _listenToNotifications();
  }

  // ✅ الاستماع للإشعارات الواردة
  void _listenToNotifications() {
    _notificationSubscription = sl<NotificationService>().onFirebaseMessageReceived.listen((message) {
      debugPrint('📱 تم استقبال إشعار عبر الـ Stream');
      
      // هنا يمكنك تحديث الـ UI أو توجيه المستخدم
      _handleNotificationNavigation(message);
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
      // مثلاً إذا كان الإشعار يريد فتح شاشة نتيجة معينة
      if (mounted) {
        // استخدم WidgetsBinding لإضافة تأخير بسيط
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // مثلاً: _navigateToScreen(screen, id);
        });
      }
    }
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        debugPrint('📱 تم فتح التطبيق عبر رابط: $initialLink');
        _pendingLink = initialLink.toString();
      }

      _linkSubscription = _appLinks.allUriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          debugPrint('📱 تم استقبال رابط: $uri');
          _pendingLink = uri.toString();
          if (mounted) setState(() {});
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في الروابط: $e');
    }
  }

  Future<void> _handlePendingLink(BuildContext context) async {
    if (_pendingLink == null || _processingDeepLink) return;

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

          if (authState.isInitializing) {
            return const SplashScreen();
          }

          // معالجة الرابط المعلق إذا كان المستخدم مسجل دخول
          if (authState.isAuthenticated && _pendingLink != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handlePendingLink(context);
            });
          }

          if (authState.isAuthenticated) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
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