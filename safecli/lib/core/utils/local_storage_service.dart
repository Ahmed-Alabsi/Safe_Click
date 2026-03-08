import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safeclik/features/auth/data/models/user_model.dart';
import 'package:safeclik/features/report/data/models/report_model.dart';

class LocalStorageService {
  static const String _usersKey = 'users';
  static const String _reportsKey = 'reports';

  // حفظ المستخدم
  Future<void> saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList(_usersKey) ?? [];
      
      // البحث عن المستخدم وتحديثه أو إضافته
      List<UserModel> users = usersJson
          .map((json) => UserModel.fromJson(jsonDecode(json)))
          .toList();
      
      final index = users.indexWhere((u) => u.id == user.id);
      if (index >= 0) {
        users[index] = user;
      } else {
        users.add(user);
      }
      
      final updatedJson = users.map((u) => jsonEncode(u.toJson())).toList();
      await prefs.setStringList(_usersKey, updatedJson);
      
      // حفظ كمستخدم حالي
      await prefs.setString('current_user', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('خطأ في حفظ المستخدم: $e');
      rethrow;
    }
  }
  
Future<void> setString(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<String?> getString(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}
  // جلب المستخدم
  Future<UserModel?> getUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // محاولة جلب المستخدم الحالي أولاً
      final currentUserJson = prefs.getString('current_user');
      if (currentUserJson != null) {
        final user = UserModel.fromJson(jsonDecode(currentUserJson));
        if (user.id == userId) {
          return user;
        }
      }
      
      // البحث في قائمة المستخدمين
      final usersJson = prefs.getStringList(_usersKey) ?? [];
      for (var json in usersJson) {
        final user = UserModel.fromJson(jsonDecode(json));
        if (user.id == userId) {
          return user;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('خطأ في جلب المستخدم: $e');
      return null;
    }
  }

  // حفظ صورة الملف الشخصي
  Future<String> saveProfileImage(File image, String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/profile_images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final fileName = 'profile_$userId.jpg';
      final newPath = '${imagesDir.path}/$fileName';
      
      await image.copy(newPath);
      return newPath;
    } catch (e) {
      debugPrint('خطأ في حفظ الصورة: $e');
      rethrow;
    }
  }



  // حفظ البلاغات
  Future<void> saveReports(List<ReportModel> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = reports.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_reportsKey, reportsJson);
    } catch (e) {
      debugPrint('خطأ في حفظ البلاغات: $e');
      rethrow;
    }
  }

  // جلب البلاغات
  Future<List<ReportModel>> getReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList(_reportsKey) ?? [];
      
      return reportsJson
          .map((json) => ReportModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('خطأ في جلب البلاغات: $e');
      return [];
    }
  }

  // مسح جميع البيانات
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('خطأ في مسح البيانات: $e');
      rethrow;
    }
  }
}
