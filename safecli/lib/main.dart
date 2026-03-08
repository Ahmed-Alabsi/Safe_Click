import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 1 Fix #1: Load environment variables FIRST before any other code.
  await dotenv.load(fileName: '.env');

  // Initialize dependency injection AFTER dotenv so ApiService reads env vars.
  await initDI();

  // Phase 6: Initialize Smart API Discovery
  await ApiClient.initialize();

  // Initialize Notifications
  await sl<NotificationService>().initialize();

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

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
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
          // Update _pendingLink without calling setState to avoid MaterialApp rebuild
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsyncValue = ref.watch(settingsProvider);
    final isDarkMode = settingsAsyncValue.value?.darkMode ?? false;

    // Phase 1 Fix #3: Read reactive AuthState — not notifier fields.
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'SafeClik',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) {
          // isInitializing is now part of state → UI rebuilds correctly
          if (authState.isInitializing) {
            return const SplashScreen();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handlePendingLink(context);
          });

          return authState.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen();
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
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/result') {
          // Phase 1 Fix #2: Safe nullable cast — no more runtime TypeError
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