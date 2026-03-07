import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/auth/data/models/user_model.dart';
import 'package:safeclik/core/utils/local_storage_service.dart';
import 'package:safeclik/core/di/di.dart';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserModel>(
  () => ProfileNotifier(),
);

class ProfileNotifier extends AsyncNotifier<UserModel> {
  final LocalStorageService _storageService = sl<LocalStorageService>();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<UserModel> build() async {
    return _loadUserData();
  }

  Future<UserModel> _loadUserData() async {
    try {
      final savedUser = await _storageService.getUser('current_user');
      if (savedUser != null) {
        return savedUser;
      }
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات المستخدم');
    }
    
    // Default mock user if not found/logged in yet
    return UserModel(
      id: 'user_123',
      name: 'أحمد محمد',
      email: 'ahmed@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      scannedLinks: 150,
      detectedThreats: 23,
      accuracyRate: 98.5,
      isEmailVerified: true,
    );
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في اختيار الصورة: $e');
      return null;
    }
  }

  Future<File?> takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في التقاط الصورة: $e');
      return null;
    }
  }

  Future<bool> updateProfileImage(File image) async {
    if (state.value == null) return false;
    try {
      state = const AsyncValue.loading();
      final currentUser = state.value!;
      
      final imagePath = await _storageService.saveProfileImage(image, currentUser.id);
      final updatedUser = currentUser.copyWith(profileImage: imagePath);
      
      await _storageService.saveUser(updatedUser);
      state = AsyncValue.data(updatedUser);
      return true;
    } catch (e) {
      debugPrint('خطأ في تحديث الصورة: $e');
      return false;
    }
  }

  Future<bool> updateName(String newName) async {
    if (state.value == null) return false;
    try {
      if (newName.isEmpty) {
        throw Exception('الاسم لا يمكن أن يكون فارغاً');
      }

      state = const AsyncValue.loading();
      final updatedUser = state.value!.copyWith(name: newName);
      
      await _storageService.saveUser(updatedUser);
      state = AsyncValue.data(updatedUser);
      return true;
    } catch (e) {
      debugPrint('خطأ في تحديث الاسم: $e');
      // On error, revert to previous state by just reloading or putting old value
      state = AsyncValue.data(state.value!);
      return false;
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    if (state.value == null) return false;
    try {
      if (newEmail.isEmpty || !newEmail.contains('@')) {
        throw Exception('البريد الإلكتروني غير صحيح');
      }

      state = const AsyncValue.loading();
      final updatedUser = state.value!.copyWith(email: newEmail, isEmailVerified: false);
      
      await _storageService.saveUser(updatedUser);
      state = AsyncValue.data(updatedUser);
      return true;
    } catch (e) {
      debugPrint('خطأ في تحديث البريد الإلكتروني: $e');
      state = AsyncValue.data(state.value!);
      return false;
    }
  }

  Future<void> incrementScannedLinks() async {
    if (state.value == null) return;
    final updatedUser = state.value!.copyWith(scannedLinks: state.value!.scannedLinks + 1);
    await _storageService.saveUser(updatedUser);
    state = AsyncValue.data(updatedUser);
  }

  Future<void> incrementDetectedThreats() async {
    if (state.value == null) return;
    final currentUser = state.value!;
    
    final newThreats = currentUser.detectedThreats + 1;
    final newAccuracy = _calculateAccuracy(currentUser.scannedLinks + 1, newThreats);
    
    final updatedUser = currentUser.copyWith(
      detectedThreats: newThreats,
      accuracyRate: newAccuracy,
    );
    
    await _storageService.saveUser(updatedUser);
    state = AsyncValue.data(updatedUser);
  }

  double _calculateAccuracy(int scanned, int threats) {
    if (scanned == 0) return 100.0;
    return ((scanned - threats) / scanned * 100).clamp(0, 100);
  }
}
