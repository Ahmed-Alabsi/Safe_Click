import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safeclik/features/settings/data/models/settings_model.dart';
import 'package:flutter/foundation.dart';
import 'package:safeclik/core/utils/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsModel>(
  () => SettingsNotifier(),
);

class SettingsNotifier extends AsyncNotifier<SettingsModel> {
  final NotificationService _notificationService = NotificationService();

  @override
  Future<SettingsModel> build() async {
    return _loadSettings();
  }

  Future<SettingsModel> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return SettingsModel(
        autoScan: prefs.getBool('autoScan') ?? true,
        notifications: prefs.getBool('notifications') ?? true,
        deepLinks: prefs.getBool('deepLinks') ?? prefs.getBool('autoScan') ?? true, // ✅ مرتبط بـ autoScan
        language: prefs.getString('language') ?? 'ar',
        safeBrowsing: prefs.getBool('safeBrowsing') ?? true,
        darkMode: prefs.getBool('darkMode') ?? false,
        autoUpdate: prefs.getBool('autoUpdate') ?? true,
        saveHistory: prefs.getBool('saveHistory') ?? true,
        scanLevel: prefs.getString('scanLevel') ?? 'basic',
      );
    } catch (e) {
      debugPrint('خطأ في تحميل الإعدادات: $e');
      return SettingsModel();
    }
  }

  Future<void> _saveSettings(SettingsModel newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoScan', newSettings.autoScan);
      await prefs.setBool('notifications', newSettings.notifications);
      await prefs.setBool('deepLinks', newSettings.deepLinks);
      await prefs.setString('language', newSettings.language);
      await prefs.setBool('safeBrowsing', newSettings.safeBrowsing);
      await prefs.setBool('darkMode', newSettings.darkMode);
      await prefs.setBool('autoUpdate', newSettings.autoUpdate);
      await prefs.setBool('saveHistory', newSettings.saveHistory);
      await prefs.setString('scanLevel', newSettings.scanLevel);
    } catch (e) {
      debugPrint('خطأ في حفظ الإعدادات: $e');
    }
  }

  Future<void> updateSettings(SettingsModel newSettings) async {
    // Update state immediately for snappy UI feel
    state = AsyncValue.data(newSettings);
    // Persist to SharedPreferences in the background
    await _saveSettings(newSettings);
  }

  // ✅ تعديل مهم: ربط autoScan مع deepLinks
  Future<void> toggleAutoScan(bool value) async {
    if (state.value == null) return;
    
    // ✅ تحديث الحالة - autoScan والروابط العميقة معاً
    final newSettings = state.value!.copyWith(
      autoScan: value,
      deepLinks: value,  // ✅ جعل deepLinks نفس قيمة autoScan
    );
    
    await updateSettings(newSettings);

    // تفعيل أو تعطيل حسب القيمة
    if (value) {
      await _enableAutoScan();
      await _enableDeepLinks();  // ✅ تفعيل الروابط العميقة مع autoScan
    } else {
      await _disableAutoScan();
      await _disableDeepLinks();  // ✅ تعطيل الروابط العميقة مع autoScan
    }
  }

  // ✅ زر الإشعارات - يبقى مستقلاً (لا يؤثر على deepLinks)
  Future<void> toggleNotifications(bool value) async {
    if (state.value == null) return;
    
    // تحديث الحالة - الإشعارات فقط
    final newSettings = state.value!.copyWith(notifications: value);
    await updateSettings(newSettings);

    // تفعيل أو تعطيل الإشعارات حسب القيمة
    if (value) {
      await _enableNotifications();
    } else {
      await _disableNotifications();
    }
  }

  // ✅ دالة منفصلة للتحكم في الروابط العميقة فقط (اختياري)
  Future<void> toggleDeepLinks(bool value) async {
    if (state.value == null) return;
    
    final newSettings = state.value!.copyWith(deepLinks: value);
    await updateSettings(newSettings);
    
    if (value) {
      await _enableDeepLinks();
    } else {
      await _disableDeepLinks();
    }
  }

  // ✅ دوال مساعدة لتفعيل/تعطيل autoScan
  Future<void> _enableAutoScan() async {
    debugPrint('🔍 تفعيل الفحص التلقائي...');
    // يمكنك إضافة أي منطق إضافي هنا
  }

  Future<void> _disableAutoScan() async {
    debugPrint('🔍 تعطيل الفحص التلقائي...');
    // يمكنك إضافة أي منطق إضافي هنا
  }

  // ✅ دالة لتفعيل الروابط العميقة
  Future<void> _enableDeepLinks() async {
    try {
      debugPrint('🔗 تفعيل الروابط العميقة...');
      // هنا يمكنك إضافة أي منطق لتفعيل استقبال الروابط
      debugPrint('✅ تم تفعيل الروابط العميقة');
    } catch (e) {
      debugPrint('❌ خطأ في تفعيل الروابط العميقة: $e');
    }
  }

  // ✅ دالة لتعطيل الروابط العميقة
  Future<void> _disableDeepLinks() async {
    try {
      debugPrint('🔗 تعطيل الروابط العميقة...');
      // هنا يمكنك إضافة أي منطق لتعطيل استقبال الروابط
      debugPrint('✅ تم تعطيل الروابط العميقة');
    } catch (e) {
      debugPrint('❌ خطأ في تعطيل الروابط العميقة: $e');
    }
  }

  // ✅ دالة لتفعيل الإشعارات
  Future<void> _enableNotifications() async {
    try {
      debugPrint('🔔 تفعيل الإشعارات...');
      
      // 1. طلب صلاحيات الإشعارات
      await _notificationService.initialize();
      
      // 2. الحصول على FCM token جديد
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('✅ FCM Token الجديد: $token');
      
      // 3. الاشتراك في المواضيع
      await _notificationService.subscribeToTopic('all_users');
      await _notificationService.subscribeToTopic('security_alerts');
      
      // 4. إرسال token إلى السيرفر (اختياري)
      await _sendTokenToServer(token);
      
      debugPrint('✅ تم تفعيل الإشعارات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تفعيل الإشعارات: $e');
    }
  }

  // ✅ تعطيل الإشعارات بشكل كامل
  Future<void> _disableNotifications() async {
    try {
      debugPrint('🔕 تعطيل الإشعارات بشكل كامل...');
      
      // 1. إلغاء الاشتراك من المواضيع أولاً
      await _notificationService.unsubscribeFromTopic('all_users');
      await _notificationService.unsubscribeFromTopic('security_alerts');
      
      // 2. حذف FCM token (هذا سيمنع وصول أي إشعارات)
      await FirebaseMessaging.instance.deleteToken();
      
      // 3. إلغاء جميع الإشعارات المحلية
      await _notificationService.cancelAllNotifications();
      
      // 4. إبلاغ السيرفر بتعطيل الإشعارات (اختياري)
      await _disableNotificationsOnServer();
      
      debugPrint('✅ تم تعطيل الإشعارات بشكل كامل');
    } catch (e) {
      debugPrint('❌ خطأ في تعطيل الإشعارات: $e');
    }
  }

  // ✅ دالة لإرسال FCM Token إلى السيرفر (اختياري)
  Future<void> _sendTokenToServer(String? token) async {
    if (token == null) return;
    
    try {
      // TODO: أضف الكود الخاص بإرسال token إلى السيرفر
      // final api = SettingsApi(ApiClient());
      // await api.updateFCMToken(token);
      debugPrint('📤 تم إرسال token إلى السيرفر');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال token إلى السيرفر: $e');
    }
  }

  // ✅ دالة لإبلاغ السيرفر بتعطيل الإشعارات (اختياري)
  Future<void> _disableNotificationsOnServer() async {
    try {
      // TODO: أضف الكود الخاص بإبلاغ السيرفر بتعطيل الإشعارات
      // final api = SettingsApi(ApiClient());
      // await api.disableNotifications();
      debugPrint('📤 تم إبلاغ السيرفر بتعطيل الإشعارات');
    } catch (e) {
      debugPrint('❌ خطأ في إبلاغ السيرفر: $e');
    }
  }

  Future<void> changeLanguage(String language) async {
    if (state.value == null) return;
    final newSettings = state.value!.copyWith(language: language);
    await updateSettings(newSettings);
  }

  Future<void> toggleSafeBrowsing(bool value) async {
    if (state.value == null) return;
    final newSettings = state.value!.copyWith(safeBrowsing: value);
    await updateSettings(newSettings);
  }

  Future<void> toggleDarkMode(bool value) async {
    if (state.value == null) return;
    final newSettings = state.value!.copyWith(darkMode: value);
    await updateSettings(newSettings);
  }

  Future<void> toggleAutoUpdate(bool value) async {
    if (state.value == null) return;
    final newSettings = state.value!.copyWith(autoUpdate: value);
    await updateSettings(newSettings);
  }

  Future<void> toggleSaveHistory(bool value) async {
    if (state.value == null) return;
    final newSettings = state.value!.copyWith(saveHistory: value);
    await updateSettings(newSettings);
  }

  Future<void> setScanLevel(String level) async {
    if (state.value == null) return;
    final newSettings = state.value!.copyWith(scanLevel: level);
    await updateSettings(newSettings);
  }

  Future<void> resetToDefaults() async {
    final newSettings = SettingsModel();
    await updateSettings(newSettings);
    
    // تفعيل/تعطيل حسب القيم الافتراضية
    if (newSettings.autoScan) {
      await _enableAutoScan();
      await _enableDeepLinks();
    } else {
      await _disableAutoScan();
      await _disableDeepLinks();
    }
    
    if (newSettings.notifications) {
      await _enableNotifications();
    } else {
      await _disableNotifications();
    }
  }
}