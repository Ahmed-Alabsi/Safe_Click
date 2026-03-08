import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_controller.dart';
import 'package:safeclik/features/scan/presentation/controllers/scan_notifier.dart';
import 'edit_profile_screen.dart';

// لا حاجة لتعريف كلاس User منفصل

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ========== رأس الملف الشخصي ==========
                    _buildProfileHeader(context, user, theme),
                    
                    const SizedBox(height: 24),
                    
                    // ========== بطاقة الإحصائيات ==========
                    // _buildStatsCard(context, user, theme),
                    
                    const SizedBox(height: 20),
                    
                    // ========== بطاقة معلومات الحساب ==========
                    _buildAccountInfoCard(context, user, theme),
                    
                    const SizedBox(height: 20),
                    
                    // ========== بطاقة معدل الأمان ==========
                    // _buildSafetyCard(context, user, theme),
                    
                    const SizedBox(height: 30),
                    
                    // ========== زر تسجيل الخروج ==========
                    _buildLogoutButton(context, ref, theme),
                    
                    const SizedBox(height: 20),
                    
                    // ========== إصدار التطبيق ==========
                    Text(
                      'الإصدار 1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  // ========== رأس الملف الشخصي ==========
Widget _buildProfileHeader(BuildContext context, dynamic user, ThemeData theme) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withValues(alpha: 0.8),
          theme.colorScheme.secondary,
        ],
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Stack(
      children: [
        // عناصر زخرفية
        Positioned(
          top: -30,
          right: -30,
          child: Icon(
            Icons.shield_rounded,
            size: 150,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -40,
          child: Icon(
            Icons.security_rounded,
            size: 180,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        
        // محتوى الرأس
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              // صورة المستخدم مع إطار متدرج
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: theme.colorScheme.surface,
                        backgroundImage: user.profileImage != null
                            ? NetworkImage(user.fullProfileImageUrl!)
                            : null,
                        child: user.profileImage == null
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 40,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    
                    // علامة الحالة
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: user.isEmailVerified 
                              ? Colors.green 
                              : Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          user.isEmailVerified 
                              ? Icons.check_rounded 
                              : Icons.access_time_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // اسم المستخدم
              Text(
                user.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // البريد الإلكتروني
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.email_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ========== زر تعديل الملف الشخصي (تحت البريد الإلكتروني) ==========
Padding(
  padding: const EdgeInsets.only(top: 16),
  child: Container(
    width: 200,
    height: 48,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {  // ✅ تم التصحيح: onTap بدلاً من onPressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          );
        },
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit_rounded,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'تعديل الملف الشخصي',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ========== بطاقة الإحصائيات ==========
  // Widget _buildStatsCard(BuildContext context, dynamic user, ThemeData theme) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: theme.cardTheme.color,
  //         borderRadius: BorderRadius.circular(25),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withValues(alpha: 0.05),
  //             blurRadius: 15,
  //             offset: const Offset(0, 5),
  //           ),
  //         ],
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.all(20),
  //         child: Column(
  //           children: [
  //             // عنوان القسم
  //             Row(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(8),
  //                   decoration: BoxDecoration(
  //                     color: theme.colorScheme.primary.withValues(alpha: 0.1),
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   child: Icon(
  //                     Icons.analytics_rounded,
  //                     color: theme.colorScheme.primary,
  //                     size: 20,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Text(
  //                   'إحصائيات النشاط',
  //                   style: theme.textTheme.titleMedium?.copyWith(
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
              
  //             const SizedBox(height: 20),
              
  //             // الإحصائيات
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceAround,
  //               children: [
  //                 _buildStatItem(
  //                   context,
  //                   'الفحوصات',
  //                   user.scannedLinks.toString(),
  //                   Icons.search_rounded,
  //                   theme.colorScheme.primary,
  //                   theme,
  //                 ),
  //                 _buildStatItem(
  //                   context,
  //                   'التهديدات',
  //                   user.detectedThreats.toString(),
  //                   Icons.warning_rounded,
  //                   theme.colorScheme.error,
  //                   theme,
  //                 ),
  //                 _buildStatItem(
  //                   context,
  //                   'الدقة',
  //                   '${user.accuracyRate.toStringAsFixed(1)}%',
  //                   Icons.percent_rounded,
  //                   theme.colorScheme.tertiary,
  //                   theme,
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ========== بطاقة معلومات الحساب ==========
  Widget _buildAccountInfoCard(BuildContext context, dynamic user, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان القسم
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'معلومات الحساب',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // البريد الإلكتروني
              _buildInfoTile(
                context,
                Icons.email_outlined,
                'البريد الإلكتروني',
                user.email,
                theme,
                iconColor: theme.colorScheme.primary,
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              
              // تاريخ التسجيل
              _buildInfoTile(
                context,
                Icons.calendar_today_outlined,
                'تاريخ التسجيل',
                _formatDate(user.createdAt),
                theme,
                iconColor: theme.colorScheme.tertiary,
              ),
              
              // const Padding(
              //   padding: EdgeInsets.symmetric(vertical: 8),
              //   child: Divider(),
              // ),
              
              // حالة البريد
              // _buildInfoTile(
              //   context,
              //   Icons.verified_outlined,
              //   'حالة البريد',
              //   user.isEmailVerified ? 'موثق' : 'غير موثق',
              //   theme,
              //   iconColor: user.isEmailVerified ? Colors.green : Colors.orange,
              //   valueColor: user.isEmailVerified ? Colors.green : Colors.orange,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== بطاقة معدل الأمان ==========
  // Widget _buildSafetyCard(BuildContext context, dynamic user, ThemeData theme) {
  //   final safePercentage = _calculateSafePercentage(user);
    
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Container(
  //       padding: const EdgeInsets.all(20),
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //           colors: [
  //             theme.colorScheme.tertiary.withValues(alpha: 0.1),
  //             theme.colorScheme.primary.withValues(alpha: 0.05),
  //           ],
  //         ),
  //         borderRadius: BorderRadius.circular(25),
  //         border: Border.all(
  //           color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
  //         ),
  //       ),
  //       child: Row(
  //         children: [
  //           // أيقونة الدرع
  //           Container(
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
  //               shape: BoxShape.circle,
  //             ),
  //             child: Icon(
  //               Icons.shield_rounded,
  //               color: theme.colorScheme.tertiary,
  //               size: 32,
  //             ),
  //           ),
            
  //           const SizedBox(width: 16),
            
  //           // المحتوى
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'معدل الأمان',
  //                   style: theme.textTheme.bodyMedium?.copyWith(
  //                     color: theme.colorScheme.onSurfaceVariant,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 4),
  //                 Row(
  //                   children: [
  //                     Text(
  //                       '$safePercentage%',
  //                       style: theme.textTheme.headlineSmall?.copyWith(
  //                         color: theme.colorScheme.tertiary,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 12),
  //                     Expanded(
  //                       child: LinearProgressIndicator(
  //                         value: safePercentage / 100,
  //                         backgroundColor: theme.colorScheme.surfaceContainerHighest,
  //                         valueColor: AlwaysStoppedAnimation<Color>(
  //                           theme.colorScheme.tertiary,
  //                         ),
  //                         minHeight: 8,
  //                         borderRadius: BorderRadius.circular(4),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ========== زر تسجيل الخروج ==========
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.error,
              theme.colorScheme.error.withValues(alpha: 0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.error.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(context, ref),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: theme.colorScheme.onError,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'تسجيل الخروج',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ========== عنصر معلومات ==========
  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    Color? iconColor,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (valueColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: valueColor ?? theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }


  // ========== تنسيق التاريخ ==========
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      return 'منذ ${(difference.inDays / 7).round()} أسابيع';
    } else if (difference.inDays < 365) {
      return 'منذ ${(difference.inDays / 30).round()} أشهر';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  // ========== حوار تسجيل الخروج ==========
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 10),
            Text(
              'تسجيل الخروج',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج من التطبيق؟',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              ref.read(scanNotifierProvider.notifier).reset();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}