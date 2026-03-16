import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/settings/presentation/providers/settings_controller.dart';
import 'package:safeclik/features/settings/data/models/settings_model.dart';
import 'package:url_launcher/url_launcher.dart'; // تأكد من إضافة هذه المكتبة في pubspec.yaml

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (settings) => _buildBody(context, settings, notifier),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SettingsModel settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        _buildGeneralSection(context, settings, notifier),
        // const SizedBox(height: 20),
        // _buildScanSettingsSection(context, settings, notifier),
        const SizedBox(height: 20),
        _buildAppearanceSection(context, settings, notifier),
        const SizedBox(height: 20),
        _buildAboutSection(context),
        // const SizedBox(height: 20),
        // _buildDangerZone(context, notifier),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.tertiary, Theme.of(context).colorScheme.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.settings, color: Theme.of(context).colorScheme.onTertiary, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإعدادات',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'خصص التطبيق حسب احتياجاتك',
                style: TextStyle(color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.7), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context, SettingsModel settings, SettingsNotifier notifier) {
    return _buildSection(
      context: context,
      title: 'عام',
      icon: Icons.settings_applications,
      children: [
        _buildSwitchTile(
          context: context,
          title: 'الإشعارات',
          subtitle: 'الإشعارات الموجهه من إدارة النظام',
          value: settings.notifications,
          icon: Icons.notifications,
          onChanged: (value) => notifier.toggleNotifications(value),
        ),
        _buildSwitchTile(
          context: context,
          title: 'فحص الرابط تلقائي',
          subtitle: 'فحص الروابط تلقائياً عند النقر عليها',
          value: settings.autoScan,  // ✅ استخدام المتغير الخاص بالمسح التلقائي
          icon: Icons.auto_awesome_rounded,  // ✅ أيقونة تناسب المسح التلقائي
          onChanged: (value) => notifier.toggleAutoScan(value),  // ✅ دالة التبديل للمسح التلقائي
        ),
        _buildLanguageTile(context, settings, notifier),
      ],
    );
  }

  // Widget _buildScanSettingsSection(BuildContext context, SettingsModel settings, SettingsNotifier notifier) {
  //   return _buildSection(
  //     context: context,
  //     title: 'إعدادات الفحص',
  //     icon: Icons.search,
  //     children: [
  //       _buildSliderTile(
  //         context: context,
  //         title: 'مهلة الفحص',
  //         value: settings.scanTimeout.toDouble(),
  //         min: 10,
  //         max: 60,
  //         divisions: 5,
  //         onChanged: (value) => notifier.setScanTimeout(value.toInt()),
  //       ),
  //       _buildScanLevelTile(context, settings, notifier),
  //     ],
  //   );
  // }

  Widget _buildAppearanceSection(BuildContext context, SettingsModel settings, SettingsNotifier notifier) {
    return _buildSection(
      context: context,
      title: 'المظهر',
      icon: Icons.palette,
      children: [
        _buildSwitchTile(
          context: context,
          title: 'الوضع الداكن',
          subtitle: 'تفعيل الوضع الداكن للتطبيق',
          value: settings.darkMode,
          icon: Icons.dark_mode,
          onChanged: (value) => notifier.toggleDarkMode(value),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'حول التطبيق',
      icon: Icons.info,
      children: [
        _buildInfoTile(context, title: 'إصدار التطبيق', value: '1.0.0', icon: Icons.tag),
        _buildInfoTile(context, title: 'آخر تحديث', value: 'يناير 2024', icon: Icons.update),
        
        // ⭐ تقييم التطبيق
        _buildActionTile(
          context, 
          title: 'تقييم التطبيق', 
          icon: Icons.star, 
          iconColor: Theme.of(context).colorScheme.primary, 
          onTap: () => _showRatingDialog(context),
        ),
        
        // 📤 مشاركة التطبيق
        // _buildActionTile(
        //   context, 
        //   title: 'مشاركة التطبيق', 
        //   icon: Icons.share, 
        //   iconColor: Theme.of(context).colorScheme.secondary, 
        //   onTap: () => _shareApp(context),
        // ),
        
        // 🔒 سياسة الخصوصية
        _buildActionTile(
          context, 
          title: 'سياسة الخصوصية', 
          icon: Icons.privacy_tip, 
          iconColor: Theme.of(context).colorScheme.tertiary, 
          onTap: () => _showPrivacyPolicy(context),
        ),
        
        // 📜 الشروط والأحكام
        _buildActionTile(
          context, 
          title: 'الشروط والأحكام', 
          icon: Icons.description, 
          iconColor: Theme.of(context).colorScheme.primary, 
          onTap: () => _showTermsAndConditions(context),
        ),
        
        // 🆘 الدعم الفني
        _buildActionTile(
          context, 
          title: 'الدعم الفني', 
          icon: Icons.contact_support, 
          iconColor: Theme.of(context).colorScheme.secondary, 
          onTap: () => _showSupportInfo(context),
        ),
      ],
    );
  }

  // Widget _buildDangerZone(BuildContext context, SettingsNotifier notifier) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
  //     ),
  //     child: Column(
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Row(
  //             children: [
  //               Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
  //               const SizedBox(width: 8),
  //               Text(
  //                 'منطقة الخطر',
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                   color: Theme.of(context).colorScheme.error,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Divider(height: 1, color: Theme.of(context).colorScheme.error),
  //         ListTile(
  //           leading: Icon(Icons.restore, color: Theme.of(context).colorScheme.error),
  //           title: Text('إعادة ضبط الإعدادات', style: TextStyle(color: Theme.of(context).colorScheme.error)),
  //           subtitle: const Text('إعادة جميع الإعدادات إلى الوضع الافتراضي'),
  //           onTap: () => _showResetDialog(context, notifier),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ⭐ واجهة تقييم التطبيق بالنجوم
  void _showRatingDialog(BuildContext context) {
    int rating = 0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تقييم التطبيق'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('كيف تقيم تجربتك مع تطبيق SafeClik؟'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              if (rating > 0) ...[
                const SizedBox(height: 20),
                Text(
                  'شكراً لتقييمك!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            if (rating > 0)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('شكراً لتقييمنا بـ $rating نجوم'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('إرسال التقييم'),
              ),
          ],
        ),
      ),
    );
  }

  // 📤 مشاركة التطبيق
  // void _shareApp(BuildContext context) {
  //   // يمكن استخدام share_plus لمشاركة التطبيق
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('سيتم إضافة ميزة المشاركة قريباً'),
  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }

  // 🔒 واجهة سياسة الخصوصية
  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سياسة الخصوصية',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrivacySection(
                      title: 'المعلومات التي نجمعها',
                      content: 'نحن نجمع المعلومات التالية:\n• الروابط التي تقوم بفحصها\n• سجل الفحوصات السابقة\n• إعدادات التطبيق الخاصة بك',
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacySection(
                      title: 'كيف نستخدم معلوماتك',
                      content: 'نستخدم معلوماتك لـ:\n• تحسين خدمة فحص الروابط\n• تخصيص تجربتك في التطبيق\n• تطوير ميزات جديدة',
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacySection(
                      title: 'حماية معلوماتك',
                      content: 'نحن نأخذ أمان بياناتك على محمل الجد. جميع المعلومات مشفرة ومحمية.',
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacySection(
                      title: 'مشاركة المعلومات',
                      content: 'لا نقوم ببيع أو مشاركة معلوماتك الشخصية مع أطراف ثالثة.',
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacySection(
                      title: 'حقوقك',
                      content: 'لديك الحق في:\n• الوصول إلى معلوماتك\n• تصحيح معلوماتك\n• حذف معلوماتك\n• الاعتراض على معالجة بياناتك',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(height: 1.5),
        ),
      ],
    );
  }

  // 📜 واجهة الشروط والأحكام
  void _showTermsAndConditions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الشروط والأحكام',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTermsSection(
                      title: 'قبول الشروط',
                      content: 'باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بهذه الشروط والأحكام.',
                    ),
                    const SizedBox(height: 16),
                    _buildTermsSection(
                      title: 'الاستخدام المسموح',
                      content: '• استخدام التطبيق لفحص الروابط المشبوهة\n• الإبلاغ عن الروابط الضارة\n• استخدام التطبيق للأغراض الشخصية فقط',
                    ),
                    const SizedBox(height: 16),
                    _buildTermsSection(
                      title: 'الاستخدام غير المسموح',
                      content: '• استخدام التطبيق لأغراض غير قانونية\n• محاولة اختراق التطبيق أو تعطيله\n• الإبلاغ الكاذب عن روابط',
                    ),
                    const SizedBox(height: 16),
                    _buildTermsSection(
                      title: 'الملكية الفكرية',
                      content: 'جميع حقوق التطبيق ومحتواه محفوظة لصالح فريق SafeClik.',
                    ),
                    const SizedBox(height: 16),
                    _buildTermsSection(
                      title: 'تعديل الشروط',
                      content: 'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إعلامك بأي تغييرات جوهرية.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(height: 1.5),
        ),
      ],
    );
  }

  // 🆘 واجهة الدعم الفني
  void _showSupportInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'الدعم الفني',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // رقم الهاتف الثابت
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone, color: Colors.white, size: 24),
                    ),
                    title: const Text('رقم الهاتف الثابت'),
                    subtitle: const Text('+966 11 234 5678'),
                    onTap: () => _launchPhoneCall('+966112345678'),
                  ),
                  const Divider(),
                  
                  // رقم الواتساب
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat, color: Colors.white, size: 24),
                    ),
                    title: const Text('رقم الواتساب'),
                    subtitle: const Text('+967 775 309 277'),
                    onTap: () => _launchWhatsApp('+967775309277'),
                  ),
                  const Divider(),
                  
                  // البريد الإلكتروني
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.email, color: Colors.white, size: 24),
                    ),
                    title: const Text('البريد الإلكتروني'),
                    subtitle: const Text('support@safeclik.com'),
                    onTap: () => _launchEmail('support@safeclik.com'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'أوقات العمل: السبت - الخميس 9:00 ص - 5:00 م',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // دالة لفتح الاتصال الهاتفي
  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  // دالة لفتح الواتساب
  Future<void> _launchWhatsApp(String phoneNumber) async {
    // إزالة + من الرقم
    final cleanNumber = phoneNumber.replaceAll('+', '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  // دالة لفتح البريد الإلكتروني
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=استفسار عن تطبيق SafeClik',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email';
    }
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildLanguageTile(BuildContext context, SettingsModel settings, SettingsNotifier notifier) {
  final theme = Theme.of(context);
  
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.language, color: theme.colorScheme.primary),
    ),
    title: const Text('اللغة'),
    subtitle: Text(settings.language == 'ar' ? 'العربية' : 'English'),
    trailing: Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: settings.language,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.colorScheme.primary,
          ),
          iconSize: 24,
          elevation: 8,
          dropdownColor: theme.colorScheme.surface,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          items: [
            DropdownMenuItem(
              value: 'ar',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: settings.language == 'ar' 
                      ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 16,
                      color: settings.language == 'ar' 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'العربية',
                      style: TextStyle(
                        color: settings.language == 'ar' 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (settings.language == 'ar') ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: settings.language == 'en' 
                      ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: settings.language == 'en' 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'English',
                      style: TextStyle(
                        color: settings.language == 'en' 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (settings.language == 'en') ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          onChanged: (value) { 
            if (value != null) notifier.changeLanguage(value); 
          },
        ),
      ),
    ),
  );
}

  // Widget _buildScanLevelTile(BuildContext context, SettingsModel settings, SettingsNotifier notifier) {
  //   const levelNames = {'basic': 'أساسي', 'standard': 'قياسي', 'deep': 'عميق'};
  //   return ListTile(
  //     leading: Container(
  //       padding: const EdgeInsets.all(8),
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
  //         shape: BoxShape.circle,
  //       ),
  //       child: Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
  //     ),
  //     title: const Text('مستوى الفحص'),
  //     subtitle: Text(levelNames[settings.scanLevel] ?? 'قياسي'),
  //     trailing: DropdownButton<String>(
  //       value: settings.scanLevel,
  //       underline: const SizedBox(),
  //       items: const [
  //         DropdownMenuItem(value: 'basic', child: Text('أساسي')),
  //         DropdownMenuItem(value: 'standard', child: Text('قياسي')),
  //         DropdownMenuItem(value: 'deep', child: Text('عميق')),
  //       ],
  //       onChanged: (value) { if (value != null) notifier.setScanLevel(value); },
  //     ),
  //   );
  // }

  // Widget _buildSliderTile({
  //   required BuildContext context,
  //   required String title,
  //   required double value,
  //   required double min,
  //   required double max,
  //   required int divisions,
  //   required Function(double) onChanged,
  // }) {
  //   return Column(
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [Text(title), Text('${value.toInt()} ثانية')],
  //         ),
  //       ),
  //       Slider(
  //         value: value, min: min, max: max, divisions: divisions,
  //         activeColor: Theme.of(context).colorScheme.primary,
  //         onChanged: onChanged,
  //       ),
  //     ],
  //   );
  // }

  Widget _buildInfoTile(BuildContext context, {required String title, required String value, required IconData icon}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
      ),
      title: Text(title),
      trailing: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  Widget _buildActionTile(BuildContext context, {required String title, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // void _showResetDialog(BuildContext context, SettingsNotifier notifier) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('إعادة ضبط الإعدادات'),
  //       content: const Text('هل أنت متأكد من إعادة ضبط جميع الإعدادات إلى القيم الافتراضية؟'),
  //       actions: [
  //         TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
  //         ElevatedButton(
  //           onPressed: () {
  //             notifier.resetToDefaults();
  //             Navigator.pop(context);
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(
  //                 content: const Text('تم إعادة ضبط الإعدادات'),
  //                 backgroundColor: Theme.of(context).colorScheme.secondary,
  //                 behavior: SnackBarBehavior.floating,
  //               ),
  //             );
  //           },
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Theme.of(context).colorScheme.onError),
  //           child: const Text('إعادة الضبط'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}