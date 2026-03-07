import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safeclik/features/settings/data/models/settings_model.dart';
import 'package:flutter/foundation.dart';

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsModel>(
  () => SettingsNotifier(),
);

class SettingsNotifier extends AsyncNotifier<SettingsModel> {
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
        language: prefs.getString('language') ?? 'ar',
        safeBrowsing: prefs.getBool('safeBrowsing') ?? true,
        darkMode: prefs.getBool('darkMode') ?? false,
        autoUpdate: prefs.getBool('autoUpdate') ?? true,
        saveHistory: prefs.getBool('saveHistory') ?? true,
        scanTimeout: prefs.getInt('scanTimeout') ?? 30,
        scanLevel: prefs.getString('scanLevel') ?? 'standard',
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
      await prefs.setString('language', newSettings.language);
      await prefs.setBool('safeBrowsing', newSettings.safeBrowsing);
      await prefs.setBool('darkMode', newSettings.darkMode);
      await prefs.setBool('autoUpdate', newSettings.autoUpdate);
      await prefs.setBool('saveHistory', newSettings.saveHistory);
      await prefs.setInt('scanTimeout', newSettings.scanTimeout);
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

  Future<void> toggleAutoScan(bool value) async {
    if (state.value == null) return;
    final newSettings = state.value!.copyWith(autoScan: value);
    await updateSettings(newSettings);
  }

  Future<void> toggleNotifications(bool value) async {
    if (state.value == null) return;
    final newSettings = state.value!.copyWith(notifications: value);
    await updateSettings(newSettings);
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

  Future<void> setScanTimeout(int seconds) async {
    if (state.value == null) return;
    final newSettings = state.value!.copyWith(scanTimeout: seconds);
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
  }
}
