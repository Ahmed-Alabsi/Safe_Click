// lib/core/utils/notification_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  
  // StreamController للإشعارات الواردة من Firebase
  final _messageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onFirebaseMessageReceived => _messageStreamController.stream;
  
  // آخر إشعار تم استقباله
  RemoteMessage? _lastFirebaseMessage;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. إعداد المنطقة الزمنية
    tz_data.initializeTimeZones();

    // 2. إعداد الإشعارات المحلية
    await _setupLocalNotifications();
    
    // 3. طلب إذن Firebase
    await _requestFirebasePermissions();
    
    // 4. الحصول على FCM Token
    await _getFCMToken();
    
    // 5. إعداد مستمعي Firebase
    _setupFirebaseListeners();

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized successfully');
  }

  Future<void> _setupLocalNotifications() async {
    // إعدادات Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // إعدادات عامة
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('📱 تم النقر على إشعار محلي: ${details.payload}');
        _handleLocalNotificationTap(details);
      },
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // قناة رئيسية للإشعارات العامة
    const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
      'safeclik_channel',
      'إشعارات SafeClik',
      description: 'القناة الرئيسية لإشعارات التطبيق',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // قناة للتنبيهات الأمنية
    const AndroidNotificationChannel securityChannel = AndroidNotificationChannel(
      'security_alerts_channel',
      'تنبيهات أمنية',
      description: 'تنبيهات الروابط الضارة والمخاطر الأمنية',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.red,
    );

    // قناة للتذكيرات
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      'reminder_channel',
      'تذكيرات',
      description: 'تذكيرات يومية لفحص الروابط',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await androidPlugin?.createNotificationChannel(mainChannel);
    await androidPlugin?.createNotificationChannel(securityChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
  }

  Future<void> _requestFirebasePermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Firebase permission granted');
    } else {
      debugPrint('⚠️ Firebase permission denied');
    }
  }

  Future<String?> _getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('🔥 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  void _setupFirebaseListeners() {
    // عندما يكون التطبيق مفتوحاً
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 [Foreground] Message received: ${message.notification?.title}');
      _showFirebaseNotification(message);
      _messageStreamController.add(message);
      _lastFirebaseMessage = message;
    });

    // عندما يكون التطبيق في الخلفية والمستخدم يضغط على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 [Background - Tap] Message opened: ${message.notification?.title}');
      _messageStreamController.add(message);
      _lastFirebaseMessage = message;
    });

    // عندما يكون التطبيق مغلقاً والمستخدم يضغط على الإشعار
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 [Terminated - Tap] Message opened: ${message.notification?.title}');
        _messageStreamController.add(message);
        _lastFirebaseMessage = message;
      }
    });

    // مراقبة تجديد التوكن
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
    });
  }

  // ✅ دالة عرض إشعار Firebase (بدون priority)
  Future<void> _showFirebaseNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      String channelId = 'safeclik_channel';
      
      if (message.data['type'] == 'security_alert') {
        channelId = 'security_alerts_channel';
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'security_alerts_channel' ? 'تنبيهات أمنية' : 'إشعارات SafeClik',
        channelDescription: notification.body ?? '',
        importance: channelId == 'security_alerts_channel' 
            ? Importance.max 
            : Importance.high,
        color: channelId == 'security_alerts_channel' 
            ? Colors.red 
            : null,
        icon: android?.smallIcon,
        playSound: true,
        enableVibration: true,
        styleInformation: channelId == 'security_alerts_channel'
            ? BigTextStyleInformation(
                notification.body ?? '',
                htmlFormatBigText: false,
                contentTitle: notification.title,
                htmlFormatContentTitle: false,
                summaryText: 'تنبيه أمني',
                htmlFormatSummaryText: false,
              )
            : null,
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: notification.title,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: message.data.toString(),
      );
    }
  }

  void _handleLocalNotificationTap(NotificationResponse details) {
    debugPrint('📱 Local notification tapped with payload: ${details.payload}');
  }

  // ✅ دالة showNotification المصححة (بدون priority)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'safeclik_channel',
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'security_alerts_channel' ? 'تنبيهات أمنية' : 'إشعارات SafeClik',
      importance: channelId == 'security_alerts_channel' ? Importance.max : Importance.high,
      color: channelId == 'security_alerts_channel' ? Colors.red : null,
      playSound: true,
      enableVibration: true,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ✅ إشعار رابط ضار
  Future<void> showDangerousLinkNotification(String link) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '⚠️ تنبيه أمني',
      body: 'تم اكتشاف رابط ضار: ${link.length > 30 ? '${link.substring(0, 30)}...' : link}',
      payload: 'dangerous_link:$link',
      channelId: 'security_alerts_channel',
    );
  }

  // ✅ إشعار اكتمال الفحص
  Future<void> showScanCompleteNotification(String result, {bool isSafe = true}) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: isSafe ? '✅ فحص آمن' : '⚠️ تحذير',
      body: result,
      payload: 'scan_complete:${isSafe ? 'safe' : 'dangerous'}',
      channelId: isSafe ? 'safeclik_channel' : 'security_alerts_channel',
    );
  }

  // ✅ جدولة إشعار تذكير (مصححة)
  Future<void> scheduleReminder() async {
    await _notificationsPlugin.zonedSchedule(
      1,
      '🔍 تذكير بفحص الروابط',
      'لا تنسَ فحص الروابط قبل فتحها للحفاظ على أمانك',
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 24)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'تذكيرات',
          channelDescription: 'قناة التذكيرات اليومية',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ✅ دوال مساعدة
  RemoteMessage? getLastFirebaseMessage() => _lastFirebaseMessage;
  void clearLastFirebaseMessage() => _lastFirebaseMessage = null;

  Future<String?> refreshFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('🔄 FCM Token refreshed: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('📌 Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('📌 Unsubscribed from topic: $topic');
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  void dispose() {
    _messageStreamController.close();
  }
}