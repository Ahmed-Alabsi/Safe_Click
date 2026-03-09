import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/auth/data/models/user_model.dart';
import 'package:safeclik/core/utils/local_storage_service.dart';
import 'package:safeclik/core/di/di.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserModel>>(
  (ref) => ProfileNotifier(),
);

class ProfileNotifier extends StateNotifier<AsyncValue<UserModel>> {
  final LocalStorageService _storageService = sl<LocalStorageService>();
  final ImagePicker _imagePicker = ImagePicker();

  ProfileNotifier() : super(const AsyncValue.loading()) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final savedUser = await _storageService.getUser('current_user');
      if (savedUser != null) {
        state = AsyncValue.data(savedUser);
      } else {
        // Default mock user if not found/logged in yet
        final defaultUser = UserModel(
          id: 'user_123',
          name: 'أحمد محمد',
          email: 'ahmed@example.com',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          scannedLinks: 150,
          detectedThreats: 23,
          accuracyRate: 98.5,
          isEmailVerified: true,
        );
        state = AsyncValue.data(defaultUser);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
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
    final currentState = state;
    if (currentState is! AsyncData<UserModel>) return false;
    
    try {
      // Set loading state
      state = const AsyncValue.loading();
      
      final currentUser = currentState.value;
      
      final imagePath = await _storageService.saveProfileImage(image, currentUser.id);
      final updatedUser = currentUser.copyWith(profileImage: imagePath);
      
      await _storageService.saveUser(updatedUser);
      
      // Update with new data
      state = AsyncValue.data(updatedUser);
      return true;
    } catch (e, stack) {
      // Revert to previous state on error
      state = AsyncValue.data(currentState.value);
      debugPrint('خطأ في تحديث الصورة: $e');
      return false;
    }
  }

  Future<bool> updateName(String newName) async {
    final currentState = state;
    if (currentState is! AsyncData<UserModel>) return false;
    
    try {
      if (newName.isEmpty) {
        throw Exception('الاسم لا يمكن أن يكون فارغاً');
      }

      // Set loading state
      state = const AsyncValue.loading();
      
      final updatedUser = currentState.value.copyWith(name: newName);
      
      await _storageService.saveUser(updatedUser);
      
      // Update with new data
      state = AsyncValue.data(updatedUser);
      return true;
    } catch (e, stack) {
      // Revert to previous state on error
      state = AsyncValue.data(currentState.value);
      debugPrint('خطأ في تحديث الاسم: $e');
      return false;
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    final currentState = state;
    if (currentState is! AsyncData<UserModel>) return false;
    
    try {
      if (newEmail.isEmpty || !newEmail.contains('@')) {
        throw Exception('البريد الإلكتروني غير صحيح');
      }

      // Set loading state
      state = const AsyncValue.loading();
      
      final updatedUser = currentState.value.copyWith(
        email: newEmail,
        isEmailVerified: false,
      );
      
      await _storageService.saveUser(updatedUser);
      
      // Update with new data
      state = AsyncValue.data(updatedUser);
      return true;
    } catch (e, stack) {
      // Revert to previous state on error
      state = AsyncValue.data(currentState.value);
      debugPrint('خطأ في تحديث البريد الإلكتروني: $e');
      return false;
    }
  }

  Future<void> incrementScannedLinks() async {
    final currentState = state;
    if (currentState is! AsyncData<UserModel>) return;
    
    final updatedUser = currentState.value.copyWith(
      scannedLinks: currentState.value.scannedLinks + 1
    );
    
    await _storageService.saveUser(updatedUser);
    state = AsyncValue.data(updatedUser);
  }

  Future<void> incrementDetectedThreats() async {
    final currentState = state;
    if (currentState is! AsyncData<UserModel>) return;
    
    final currentUser = currentState.value;
    
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

  // دالة لإعادة تحميل البيانات
  Future<void> refreshUserData() async {
    await _loadUserData();
  }
}