import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/report/presentation/providers/report_controller.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_controller.dart';
import 'package:safeclik/features/report/data/models/report_model.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _linkFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  
  String? _selectedCategory;
  int _selectedSeverity = 3;
  late AnimationController _animationController;
  bool _isSubmitting = false;

  ReportModel? _lastDeletedReport;

  // 🗑️ متغيرات للتراجع عن الحذف الكل
  List<ReportModel>? _lastDeletedAllReports;

  final List<String> _categories = [
    'تصيد احتيالي',
    'برمجيات خبيثة',
    'احتيال مالي',
    'محتوى غير لائق',
    'بريد عشوائي',
    'انتهاك خصوصية',
    'أخرى',
  ];

  final List<Map<String, dynamic>> _severityLevels = [
    {'value': 1, 'label': 'منخفض', 'color': Colors.green},
    {'value': 2, 'label': 'متوسط', 'color': Colors.blue},
    {'value': 3, 'label': 'عالي', 'color': Colors.orange},
    {'value': 4, 'label': 'خطير', 'color': Colors.deepOrange},
    {'value': 5, 'label': 'حرج', 'color': Colors.red},
  ];

  Color _getSeverityColor(BuildContext context, int severity) {
    switch (severity) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.deepOrange;
      case 5: return Colors.red;
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _descriptionController.dispose();
    _linkFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 🔄 دالة التراجع عن حذف بلاغ فردي
  void _undoDeleteReport() {
    if (_lastDeletedReport == null) return;
    
    try {
      final reportToRestore = _lastDeletedReport!;
      // Restore locally
      ref.read(reportProvider.notifier).addReportLocally(reportToRestore);
      
      // Background sync restore
      ref.read(reportProvider.notifier).restoreReportsBulk([reportToRestore.id]);
      
      ScaffoldMessenger.of(context).clearSnackBars();
      
      _lastDeletedReport = null;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التراجع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔄 دالة التراجع عن مسح جميع البلاغات
  void _undoDeleteAllReports() {
    if (_lastDeletedAllReports == null) return;
    
    try {
      // Restore locally
      ref.read(reportProvider.notifier).addReportsLocally(_lastDeletedAllReports!);
      
      // Background sync restore
      final ids = _lastDeletedAllReports!.map((r) => r.id).toList();
      ref.read(reportProvider.notifier).restoreReportsBulk(ids);
      
      ScaffoldMessenger.of(context).clearSnackBars();
      
      _lastDeletedAllReports = null;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التراجع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final reports = reportState.value ?? [];
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        // appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   leading: Container(
        //     margin: const EdgeInsets.all(8),
        //     decoration: BoxDecoration(
        //       color: theme.colorScheme.primary.withValues(alpha: 0.1),
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     child: IconButton(
        //       icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.primary),
        //       onPressed: () => Navigator.pop(context),
        //     ),
        //   ),
        //   title: Text(
        //     'الإبلاغ عن رابط',
        //     style: theme.textTheme.titleLarge?.copyWith(
        //       fontWeight: FontWeight.bold,
        //       color: theme.colorScheme.onSurface,
        //     ),
        //   ),
        //   centerTitle: true,
        //   actions: [
        //     Container(
        //       margin: const EdgeInsets.all(8),
        //       decoration: BoxDecoration(
        //         color: theme.colorScheme.primary.withValues(alpha: 0.1),
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //       child: _buildHistoryButton(context, reports.length),
        //     ),
        //   ],
        // ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(context, reports.length),
              const SizedBox(height: 24),
              _buildForm(context),
              const SizedBox(height: 24),
              _buildGuidelines(context),
              const SizedBox(height: 24),
              _buildErrorWidget(context),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ هيدر بارز وجميل
  Widget _buildHeader(BuildContext context, int reportsCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // أيقونة التطبيق
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              
              // النصوص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حماية المجتمع',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ساهم في جعل الإنترنت مكاناً آمناً للجميع',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // زر السجل الاحترافي
              _buildHistoryButton(context, reportsCount),
            ],
          ),
        ],
      ),
    );
  }

  

  // ✅ زر التاريخ البارز
  Widget _buildHistoryButton(BuildContext context, int count) {
    return InkWell(
      onTap: () => _showReportsBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            if (count > 0)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (count > 0) const SizedBox(width: 8),
            const Icon(Icons.history_edu_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            const Text(
              'سجلاتي',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ نموذج الإبلاغ البارز
  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل البلاغ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLinkField(context),
          const SizedBox(height: 20),
          _buildCategoryField(context),
          const SizedBox(height: 20),
          _buildSeverityField(),
          const SizedBox(height: 20),
          _buildDescriptionField(context),
          const SizedBox(height: 30),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ✅ حقل الرابط البارز
  Widget _buildLinkField(BuildContext context) {
  final theme = Theme.of(context);
  final isFocused = _linkFocusNode.hasFocus;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.link_rounded, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'الرابط المشبوه',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ],
      ),
      const SizedBox(height: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _linkController,
          focusNode: _linkFocusNode,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'https://example.com',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3), // ✅ لون خفيف جداً بدلاً من الأزرق
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            prefixIcon: Icon(
              Icons.link_rounded,
              color: theme.colorScheme.primary.withValues(alpha: 0.7), // ✅ لون ثابت بدون تغيير
            ),
            suffixIcon: _linkController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _linkController.clear(),
                  )
                : null,
          ),
          textDirection: TextDirection.ltr,
          onTap: () => setState(() {}),
          onChanged: (_) => setState(() {}),
        ),
      ),
    ],
  );
}

  // ✅ حقل نوع التهديد البارز - تصميم محدث مع Dropdown
Widget _buildCategoryField(BuildContext context) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.category_rounded, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'نوع التهديد',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ],
      ),
      const SizedBox(height: 8),
      
      // تصميم Dropdown محدث وأجمل
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // فتح القائمة المنسدلة
                FocusScope.of(context).unfocus();
                _showCategoryDropdown(context);
              },
              borderRadius: BorderRadius.circular(20),
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // أيقونة مختارة حسب الفئة
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _selectedCategory != null
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getCategoryIcon(_selectedCategory ?? 'category'),
                        size: 18,
                        color: _selectedCategory != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // النص المعروض
                    Expanded(
                      child: Text(
                        _selectedCategory ?? 'اختر نوع التهديد',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _selectedCategory != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: _selectedCategory != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    
                    // السهم مع تصميم جميل
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      
      // عرض الفئة المختارة بشكل بارز (اختياري)
      if (_selectedCategory != null)
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'تم اختيار: $_selectedCategory',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

// دالة مساعدة لعرض القائمة المنسدلة بشكل جميل
Future<void> _showCategoryDropdown(BuildContext context) async {
  final theme = Theme.of(context);
  final result = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض السحب
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // العنوان
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.category_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'اختر نوع التهديد',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // قائمة الفئات
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, category),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(alpha: 0.1),
                                  theme.colorScheme.secondary.withValues(alpha: 0.1),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // أيقونة الفئة
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              size: 20,
                              color: isSelected ? Colors.white : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // اسم الفئة
                          Expanded(
                            child: Text(
                              category,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          
                          // علامة الاختيار
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
  
  if (result != null && mounted) {
    setState(() {
      _selectedCategory = result;
    });
  }
}

// دالة مساعدة للحصول على أيقونة لكل فئة
IconData _getCategoryIcon(String category) {
  switch (category) {
    case 'تصيد احتيالي':
      return Icons.phishing_rounded;
    case 'برمجيات خبيثة':
      return Icons.bug_report_rounded;
    case 'احتيال مالي':
      return Icons.attach_money_rounded;
    case 'محتوى غير لائق':
      return Icons.warning_rounded;
    case 'بريد عشوائي':
      return Icons.mark_email_unread_rounded;
    case 'انتهاك خصوصية':
      return Icons.privacy_tip_rounded;
    case 'أخرى':
      return Icons.more_horiz_rounded;
    default:
      return Icons.category_rounded;
  }
}

  // ✅ حقل درجة الخطورة البارز
  Widget _buildSeverityField() {
    final theme = Theme.of(context);

    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.speed_rounded, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'درجة الخطورة',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: _severityLevels.map((level) {
              final isSelected = _selectedSeverity == level['value'];
              final color = level['color'] as Color;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSeverity = level['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                color,
                                color.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          level['value'].toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          level['label'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ✅ حقل الوصف البارز
  Widget _buildDescriptionField(BuildContext context) {
  final theme = Theme.of(context);
  final isFocused = _descriptionFocusNode.hasFocus;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.description_rounded, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'وصف إضافي',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            ' (اختياري)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          maxLines: 4,
          maxLength: 500,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'أضف أي تفاصيل إضافية عن الرابط...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5), // ✅ لون رمادي عند التركيز
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: isFocused
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15) // ✅ تغيير طفيف عند التركيز
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            counterStyle: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => setState(() {}),
        ),
      ),
    ],
  );
}

  // ✅ زر الإرسال البارز
  Widget _buildSubmitButton() {
    final theme = Theme.of(context);
    final isGuest = ref.watch(authProvider).isGuest;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting 
            ? null 
            : isGuest 
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "يجب تسجيل الدخول للإبلاغ عن الروابط",
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        action: SnackBarAction(
                          label: "تسجيل الدخول",
                          textColor: theme.colorScheme.primaryContainer,
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'إرسال البلاغ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ✅ إرشادات الإبلاغ البارزة
  Widget _buildGuidelines(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.05),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إرشادات الإبلاغ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGuidelineItem(context, 'تأكد من صحة الرابط قبل الإبلاغ', Icons.check_circle_rounded),
          _buildGuidelineItem(context, 'الإبلاغ الكاذب قد يعرضك للمساءلة', Icons.warning_amber_rounded),
          _buildGuidelineItem(context, 'سيتم مراجعة البلاغ خلال 24 ساعة', Icons.access_time_rounded),
          _buildGuidelineItem(context, 'يمكنك متابعة حالة البلاغ عبر رقم التتبع', Icons.track_changes_rounded),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final reportNotifier = ref.read(reportProvider.notifier);
    final lastError = reportNotifier.lastError;
    if (lastError == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lastError,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                reportNotifier.clearError();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ باقي الدوال مع تحسينات بسيطة
  void _showReportsBottomSheet(BuildContext context) {
    final reportState = ref.read(reportProvider);
    final reports = reportState.value ?? [];
    final reportNotifier = ref.read(reportProvider.notifier);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'سجل البلاغات',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (reports.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_sweep_rounded, color: theme.colorScheme.error),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmClearAllReports(reportNotifier);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 30),
            Expanded(
              child: reportState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'حدث خطأ في تحميل البلاغات',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                data: (reports) {
                  if (reports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'لا توجد بلاغات بعد',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'قم بإرسال بلاغ جديد ليظهر هنا',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => 
                      _buildBottomSheetReportCard(context, reports[index], reportNotifier),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetReportCard(BuildContext context, ReportModel report, ReportNotifier notifier) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.tag_rounded, size: 12, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  report.trackingNumber ?? 'بدون رقم',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(context, report.status),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.colorScheme.error, size: 16),
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteReport(report, notifier);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.link,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  report.category,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getSeverityColor(context, report.severity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getSeverityLabel(report.severity),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getSeverityColor(context, report.severity),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${report.reportDate.day}/${report.reportDate.month}/${report.reportDate.year}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSeverityLabel(int severity) {
    switch (severity) {
      case 1: return 'منخفض';
      case 2: return 'متوسط';
      case 3: return 'عالي';
      case 4: return 'خطير';
      case 5: return 'حرج';
      default: return 'غير معروف';
    }
  }

  Widget _buildStatusBadge(BuildContext context, String? status) {
    final cfg = _statusConfig(status);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.$1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        cfg.$2,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cfg.$1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _statusConfig(String? status) {
    switch (status) {
      case 'pending':
        return (Colors.orange, 'قيد المراجعة');
      case 'reviewing':
        return (Colors.blue, 'قيد التحقيق');
      case 'confirmed':
        return (Colors.red, 'تم التأكيد');
      case 'rejected':
        return (Colors.grey, 'مرفوض');
      case 'resolved':
        return (Colors.green, 'تم الحل');
      default:
        return (Colors.orange, 'قيد المراجعة');
    }
  }

  void _showReportDetails(BuildContext context, ReportModel report) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(0, 207, 104, 104),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.description_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'تفاصيل البلاغ',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailItem(context, 'رقم التتبع', report.trackingNumber ?? 'غير متوفر', Icons.tag_rounded),
            _buildDetailItem(context, 'الرابط', report.link, Icons.link_rounded, isSelectable: true),
            _buildDetailItem(context, 'نوع التهديد', report.category, Icons.category_rounded),
            _buildDetailItem(context, 'درجة الخطورة', _getSeverityLabel(report.severity), Icons.speed_rounded,
                valueColor: _getSeverityColor(context, report.severity)),
            _buildDetailItem(context, 'الحالة', _statusConfig(report.status).$2, Icons.info_rounded,
                valueColor: _statusConfig(report.status).$1),
            _buildDetailItem(context, 'تاريخ الإبلاغ', 
                '${report.reportDate.year}/${report.reportDate.month}/${report.reportDate.day}', 
                Icons.calendar_today_rounded),
            if (report.description.isNotEmpty)
              _buildDetailItem(context, 'وصف إضافي', report.description, Icons.description_rounded),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon,
      {Color? valueColor, bool isSelectable = false}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                if (isSelectable)
                  SelectableText(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? theme.colorScheme.onSurface,
                    ),
                  )
                else
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteReport(ReportModel report, ReportNotifier notifier) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('حذف البلاغ', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('هل أنت متأكد من حذف هذا البلاغ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        _lastDeletedReport = report;
        
        // 1. Optimistic update
        notifier.deleteReportLocally(report.id);
        
        // 2. Background sync
        notifier.deleteReport(report.id);
        
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('تم حذف البلاغ')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: _undoDeleteReport,
            ),
          ),
        );
        
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('فشل حذف البلاغ: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearAllReports(ReportNotifier notifier) async {
    final currentReports = ref.read(reportProvider).value ?? [];
    
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('حذف جميع البلاغات', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من حذف جميع البلاغات السابقة؟'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'سيتم حذف ${currentReports.length} بلاغ',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      try {
        final deletedReports = List<ReportModel>.from(currentReports);
        _lastDeletedAllReports = deletedReports;
        
        // 1. Optimistic update
        notifier.clearAllReportsLocally();
        
        // 2. Background sync
        notifier.clearAllReports();
        
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_sweep, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('تم حذف جميع البلاغات')),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: _undoDeleteAllReports,
            ),
          ),
        );
        
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف البلاغات: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_linkController.text.trim().isEmpty) {
      _showSnackBar('يرجى إدخال الرابط المشبوه', true);
      return;
    }

    if (_selectedCategory == null) {
      _showSnackBar('يرجى اختيار نوع التهديد', true);
      return;
    }

    if (!_isValidUrl(_linkController.text)) {
      _showSnackBar('يرجى إدخال رابط صحيح (مثال: https://example.com)', true);
      return;
    }

    setState(() => _isSubmitting = true);

    final currentUser = ref.read(authProvider).user;
    final reportNotifier = ref.read(reportProvider.notifier);

    final success = await reportNotifier.submitReport(
      link: _linkController.text.trim(),
      category: _selectedCategory!,
      description: _descriptionController.text.trim(),
      severity: _selectedSeverity,
      reporterName: currentUser?.name ?? 'مستخدم مجهول',
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showSuccessDialog();
        _clearForm();
      }
    } else if (mounted) {
      _showSnackBar(reportNotifier.lastError ?? 'فشل إرسال البلاغ', true);
    }
  }

  bool _isValidUrl(String url) {
    try {
      String normalizedUrl = url.trim();
      // إضافة البروتوكول إذا لم يكن موجوداً
      if (!normalizedUrl.startsWith('http://') &&
          !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'https://$normalizedUrl';
      }
      final uri = Uri.tryParse(normalizedUrl);
      return uri != null &&
          uri.hasScheme &&
          uri.host.isNotEmpty &&
          uri.host.contains('.');
    } catch (e) {
      return false;
    }
  }

  void _clearForm() {
    _linkController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedSeverity = 3;
    });
  }

  void _showSnackBar(String message, bool isError) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    final reportState = ref.read(reportProvider);
    final reports = reportState.value ?? [];
    final lastReport = reports.isNotEmpty ? reports.first : null;
    final trackingNumber = lastReport?.trackingNumber ?? 'جاري إنشاء رقم التتبع';
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green,
                      Colors.green.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم استلام البلاغ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'شكراً لك على المساهمة في حماية المجتمع',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'رقم تتبع البلاغ:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      trackingNumber,
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}