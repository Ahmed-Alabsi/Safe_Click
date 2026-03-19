import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/settings/presentation/providers/settings_controller.dart';
import 'package:safeclik/features/settings/data/models/settings_model.dart';
import 'package:safeclik/features/settings/presentation/providers/rating_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_controller.dart';

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
        data: (settings) => _buildBody(context, ref, settings, notifier),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, SettingsModel settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        _buildGeneralSection(context, settings, notifier),
        const SizedBox(height: 20),
        _buildScanSettingsSection(context, settings, notifier),
        const SizedBox(height: 20),
        _buildAppearanceSection(context, settings, notifier),
        const SizedBox(height: 20),
        _buildAboutSection(context, ref),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.tertiary, theme.colorScheme.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.settings, color: theme.colorScheme.onTertiary, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإعدادات',
                style: TextStyle(
                  color: theme.colorScheme.onTertiary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'خصص التطبيق حسب احتياجاتك',
                style: TextStyle(color: theme.colorScheme.onTertiary.withValues(alpha: 0.7), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
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
          value: settings.autoScan,
          icon: Icons.auto_awesome_rounded,
          onChanged: (value) => notifier.toggleAutoScan(value),
        ),
        _buildLanguageTile(context, settings, notifier),
      ],
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
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
            iconSize: 24,
            elevation: 8,
            dropdownColor: theme.colorScheme.surface,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            items: [
              _buildLanguageItem(theme, 'ar', 'العربية', Icons.flag_rounded, settings.language == 'ar'),
              _buildLanguageItem(theme, 'en', 'English', Icons.language_rounded, settings.language == 'en'),
            ],
            onChanged: (value) {
              if (value != null) notifier.changeLanguage(value);
            },
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildLanguageItem(ThemeData theme, String value, String label, IconData icon, bool isSelected) {
    return DropdownMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanSettingsSection(BuildContext context, SettingsModel settings, SettingsNotifier notifier) {
    return _buildSection(
      context: context,
      title: 'إعدادات الفحص',
      icon: Icons.search,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'اختر وضع الفحص المناسب لاحتياجاتك:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _buildScanModeCard(
          context: context,
          title: 'فحص سريع',
          description: 'فحص أساسي وسريع للروابط المشبوهة.',
          timeDescription: 'أقل من 3 ثوانٍ',
          securityLevel: 'أمان جيد',
          icon: Icons.bolt_rounded,
          isSelected: settings.scanLevel == 'basic',
          onTap: () {
            notifier.setScanLevel('basic');
          },
        ),
        _buildScanModeCard(
          context: context,
          title: 'فحص متوازن',
          description: 'فحص قياسي مع تدقيق إضافي للروابط.',
          timeDescription: 'حوالي 6 ثانية',
          securityLevel: 'أمان عالٍ',
          icon: Icons.shutter_speed_rounded,
          isSelected: settings.scanLevel == 'standard',
          onTap: () {
            notifier.setScanLevel('standard');
          },
        ),
        _buildScanModeCard(
          context: context,
          title: 'فحص عميق',
          description: 'فحص شامل وتفصيلي لجميع التهديدات.',
          timeDescription: 'حوالي 12 ثانية',
          securityLevel: 'أقصى درجات الأمان',
          icon: Icons.security_rounded,
          isSelected: settings.scanLevel == 'deep',
          onTap: () {
            notifier.setScanLevel('deep');
          },
        ),
      ],
    );
  }

  Widget _buildScanModeCard({
    required BuildContext context,
    required String title,
    required String description,
    required String timeDescription,
    required String securityLevel,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        timeDescription,
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.secondary),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.shield_rounded, size: 14, color: colorScheme.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        securityLevel,
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.tertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildAboutSection(BuildContext context, WidgetRef ref) {
    return _buildSection(
      context: context,
      title: 'حول التطبيق',
      icon: Icons.info,
      children: [
        _buildInfoTile(context, title: 'إصدار التطبيق', value: '1.0.0', icon: Icons.tag),
        _buildInfoTile(context, title: 'آخر تحديث', value: 'يناير 2024', icon: Icons.update),
        _buildActionTile(
          context,
          title: 'تقييم التطبيق',
          icon: Icons.star,
          iconColor: Theme.of(context).colorScheme.primary,
          onTap: () {
            if (ref.read(authProvider).isGuest) {
              _showGuestMessage(context);
            } else {
              _showRatingDialog(context);
            }
          },
        ),
        _buildActionTile(
          context,
          title: 'سياسة الخصوصية',
          icon: Icons.privacy_tip,
          iconColor: Theme.of(context).colorScheme.tertiary,
          onTap: () => _showPrivacyPolicy(context),
        ),
        _buildActionTile(
          context,
          title: 'الشروط والأحكام',
          icon: Icons.description,
          iconColor: Theme.of(context).colorScheme.primary,
          onTap: () => _showTermsAndConditions(context),
        ),
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

  void _showGuestMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("يجب تسجيل الدخول لتقييم التطبيق", style: TextStyle(fontFamily: 'Cairo')),
        action: SnackBarAction(
          label: "تسجيل الدخول",
          textColor: Theme.of(context).colorScheme.primaryContainer,
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RatingDialog(),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    // ... Existing detailed privacy policy bottom sheet logic ...
    // Note: I'll keep the core structure but slightly simplify for the rewrite or just restore it fully.
    // Restoring fully as it was premium.
    _showPremiumBottomSheet(
      context,
      title: 'سياسة الخصوصية',
      subtitle: 'كيف نحمي بياناتك ونستخدمها',
      icon: Icons.privacy_tip_rounded,
      cards: [
        _buildInfoCard(context, Icons.collections_bookmark_rounded, 'المعلومات التي نجمعها', '• الروابط التي تقوم بفحصها\n• سجل الفحوصات السابقة\n• إعدادات التطبيق الخاصة بك', Theme.of(context).colorScheme.primary),
        _buildInfoCard(context, Icons.analytics_rounded, 'كيف نستخدم معلوماتك', '• تحسين خدمة فحص الروابط\n• تخصيص تجربتك في التطبيق\n• تطوير ميزات جديدة', Theme.of(context).colorScheme.secondary),
        _buildInfoCard(context, Icons.security_rounded, 'حماية معلوماتك', 'نحن نأخذ أمان بياناتك على محمل الجد. جميع المعلومات مشفرة ومحمية.', Theme.of(context).colorScheme.tertiary),
      ],
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    _showPremiumBottomSheet(
      context,
      title: 'الشروط والأحكام',
      subtitle: 'يرجى قراءة الشروط بعناية',
      icon: Icons.description_rounded,
      cards: [
        _buildInfoCard(context, Icons.check_circle_rounded, 'قبول الشروط', 'باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بهذه الشروط والأحكام.', Colors.green),
        _buildInfoCard(context, Icons.thumb_up_rounded, 'الاستخدام المسموح', '• استخدام التطبيق لفحص الروابط المشبوهة\n• الإبلاغ عن الروابط الضارة', Theme.of(context).colorScheme.primary),
        _buildInfoCard(context, Icons.copyright_rounded, 'الملكية الفكرية', 'جميع حقوق التطبيق ومحتواه محفوظة لصالح فريق SafeClick.', Colors.purple),
      ],
      showConfirmButton: true,
    );
  }

  void _showPremiumBottomSheet(BuildContext context, {required String title, required String subtitle, required IconData icon, required List<Widget> cards, bool showConfirmButton = false}) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 50, height: 5, decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: theme.colorScheme.primary)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), Text(subtitle, style: theme.textTheme.bodySmall)])),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: ListView(padding: const EdgeInsets.all(20), children: cards)),
            if (showConfirmButton)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('موافق'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String title, String content, Color color) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 12), Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color))]),
          const SizedBox(height: 12),
          Text(content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showSupportInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الدعم الفني', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildSupportTile(context, Icons.phone, 'رقم الهاتف', '+966 11 234 5678', () => _launchURL('tel:+966112345678')),
            _buildSupportTile(context, Icons.chat, 'واتساب', '+967 775 309 277', () => _launchURL('https://wa.me/967775309277')),
            _buildSupportTile(context, Icons.email, 'البريد الإلكتروني', 'support@safeclik.com', () => _launchURL('mailto:support@safeclik.com')),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _buildSwitchTile({required BuildContext context, required String title, required String subtitle, required bool value, required IconData icon, required Function(bool) onChanged}) {
    return SwitchListTile(
      title: Text(title), subtitle: Text(subtitle), value: value, onChanged: onChanged,
      secondary: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(shape: BoxShape.circle), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
    );
  }


  Widget _buildInfoTile(BuildContext context, {required String title, required String value, required IconData icon}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title), trailing: Text(value),
    );
  }

  Widget _buildActionTile(BuildContext context, {required String title, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: onTap,
    );
  }
}

class RatingDialog extends ConsumerStatefulWidget {
  const RatingDialog({super.key});
  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  int rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentState = ref.read(ratingProvider).value;
    if (currentState != null) {
      rating = currentState.rating ?? 0;
      _commentController.text = currentState.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratingState = ref.watch(ratingProvider);
    final isSubmitting = ratingState.isLoading;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(30)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 60),
              const SizedBox(height: 16),
              const Text('تقييم التطبيق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('كيف تقيم تجربتك مع SafeClick؟', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(index < rating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 40),
                    onPressed: isSubmitting ? null : () => setState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(hintText: 'أخبرنا المزيد (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: rating == 0 || isSubmitting ? null : () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await ref.read(ratingProvider.notifier).submitRating(rating, _commentController.text);
                        if (success && mounted) {
                          navigator.pop();
                          messenger.showSnackBar(const SnackBar(content: Text('شكراً لتقييمك!'), backgroundColor: Colors.green));
                        }
                      },
                      child: isSubmitting ? const CircularProgressIndicator() : const Text('إرسال'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}