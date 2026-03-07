import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // إعداد المنطقة الزمنية
    tz_data.initializeTimeZones();

    // إعدادات Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // إعدادات عامة
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // تهيئة الإشعارات
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // معالجة النقر على الإشعار
      },
    );

    _isInitialized = true;
  }

  // عرض إشعار فوري
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'safeclik_channel',
      'إشعارات SafeClik',
      channelDescription: 'قناة إشعارات تطبيق SafeClik',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
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

  // عرض إشعار عند اكتشاف رابط ضار
  Future<void> showDangerousLinkNotification(String link) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '⚠ تنبيه أمني',
      body: 'تم اكتشاف رابط ضار: $link',
      payload: 'dangerous_link',
    );
  }

  // عرض إشعار عند اكتمال الفحص
  Future<void> showScanCompleteNotification(String result) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '✅ اكتمل الفحص',
      body: result,
      payload: 'scan_complete',
    );
  }

  // جدولة إشعار تذكير
  Future<void> scheduleReminder() async {
    await _notificationsPlugin.zonedSchedule(
      1,
      'تذكير بفحص الروابط',
      'لا تنسَ فحص الروابط قبل فتحها للحفاظ على أمانك',
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 24)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'تذكيرات',
          channelDescription: 'قناة التذكيرات اليومية',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // إلغاء إشعار معين
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
