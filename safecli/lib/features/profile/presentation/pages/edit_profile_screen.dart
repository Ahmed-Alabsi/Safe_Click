import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:safeclik/features/auth/presentation/providers/auth_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _selectedImage;
  bool _isLoading = false;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _successMessage = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم اختيار الصورة بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _successMessage = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final currentUser = ref.read(authProvider).user;
    bool nameUpdated = false;
    bool imageUpdated = false;

    // تحديث الاسم - استخدام authProvider مباشرة
    if (_nameController.text.trim() != currentUser?.name) {
      nameUpdated = await authNotifier.updateProfile(name: _nameController.text.trim());
      if (nameUpdated) {
        debugPrint('✅ تم تحديث الاسم بنجاح في authProvider');
      }
    }

    // تحديث الصورة - استخدام authProvider مباشرة
    if (_selectedImage != null) {
      imageUpdated = await authNotifier.updateProfileImage(_selectedImage!.path);
      if (imageUpdated) {
        debugPrint('✅ تم تحديث الصورة بنجاح في authProvider');
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (nameUpdated || imageUpdated) {
        String message = '';
        if (nameUpdated && imageUpdated) {
          message = 'تم تحديث الاسم والصورة بنجاح';
        } else if (nameUpdated) {
          message = 'تم تحديث الاسم بنجاح';
        } else if (imageUpdated) {
          message = 'تم تحديث الصورة بنجاح';
        }

        // تحديث profileProvider أيضاً إذا كنت تستخدمه
        // ref.read(profileProvider.notifier).refreshUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد تغييرات للحفظ'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // صورة المستخدم
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: (_selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (user != null && user.profileImage != null
                                    ? NetworkImage(user.fullProfileImageUrl!)
                                    : null)) as ImageProvider?,
                            child: _selectedImage == null && (user == null || user.profileImage == null)
                                ? Text(
                                    (user?.name != null && user!.name.isNotEmpty)
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 40),
                                  )
                                : null,
                          ),
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('تغيير الصورة'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // ✅ حقل الاسم المحسن
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.person_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        hintText: 'أدخل اسمك الكامل',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الاسم مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // ✅ حقل البريد الإلكتروني المحسن (غير قابل للتعديل)
                    TextFormField(
                      initialValue: user?.email,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.email_rounded,
                          color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // ✅ زر الحفظ المحسن
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'حفظ التغييرات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}