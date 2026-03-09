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

  // 🗑️ متغيرات للتراجع عن الحذف
  ReportModel? _lastDeletedReport;
  Timer? _undoTimer;

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
    {'value': 1, 'label': 'منخفض'},
    {'value': 2, 'label': 'متوسط'},
    {'value': 3, 'label': 'عالي'},
    {'value': 4, 'label': 'خطير'},
    {'value': 5, 'label': 'حرج'},
  ];

  Color _getSeverityColor(BuildContext context, int severity) {
    switch (severity) {
      case 1: return Theme.of(context).colorScheme.tertiary;
      case 2: return Theme.of(context).colorScheme.primary;
      case 3: return Theme.of(context).colorScheme.secondary;
      case 4: return Theme.of(context).colorScheme.error;
      case 5: return Theme.of(context).colorScheme.error;
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
    _undoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final reports = reportState.value ?? [];

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.tertiary,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(context, reports.length),
                const SizedBox(height: 20),
                _buildForm(context),
                const SizedBox(height: 20),
                _buildGuidelines(context),
                const SizedBox(height: 20),
                _buildErrorWidget(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ الهيدر مع زر السجل الاحترافي
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

  // ✅ تعديل مكان زر السجل ليكون مقابل "تفاصيل البلاغ"
  Widget _buildForm(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان تفاصيل البلاغ مع زر السجل مقابله
            Row(
              children: [
                Text(
                  'تفاصيل البلاغ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
      ),
    );
  }

  // ✅ دالة عرض سجل البلاغات في BottomSheet
  void _showReportsBottomSheet(BuildContext context) {
    final reportState = ref.read(reportProvider);
    final reports = reportState.value ?? [];
    final reportNotifier = ref.read(reportProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // مؤشر السحب
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            
            // العنوان مع زر حذف الكل
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history_edu_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'سجل البلاغات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: Colors.blue),
                  onPressed: () => ref.read(reportProvider.notifier).refreshReports(),
                  tooltip: 'تحديث',
                ),
                const Spacer(),
                
                // زر حذف الكل
                if (reports.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_sweep,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // إغلاق الـ BottomSheet
                        _confirmClearAllReports(context, reportNotifier);
                      },
                      tooltip: 'حذف الكل',
                    ),
                  ),
              ],
            ),
            const Divider(height: 30),
            
            // قائمة البلاغات
            Expanded(
              child: reportState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'حدث خطأ في تحميل البلاغات',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
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
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد بلاغات بعد',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'قم بإرسال بلاغ جديد ليظهر هنا',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
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

  // ✅ بطاقة البلاغ المخصصة للـ BottomSheet مع ميزة التراجع
  Widget _buildBottomSheetReportCard(BuildContext context, ReportModel report, ReportNotifier notifier) {
    final displayUrl = report.link.length > 35
        ? '${report.link.substring(0, 32)}...'
        : report.link;

    final date = report.reportDate;
    final dateStr =
        '${date.day}/${date.month}/${date.year}';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReportDetails(context, report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: رقم التتبع والحالة وزر الحذف
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.tag,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.trackingNumber ?? 'بدون رقم',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context, report.status),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.error,
                        size: 16,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // إغلاق الـ BottomSheet
                        _confirmDeleteReport(context, report, notifier);
                      },
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // الرابط
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      displayUrl,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // الصف السفلي: التصنيف ودرجة الخطورة والتاريخ
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      report.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(context, report.severity).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getSeverityColor(context, report.severity).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _getSeverityLabel(report.severity),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getSeverityColor(context, report.severity),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ عرض تفاصيل البلاغ
  void _showReportDetails(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'تفاصيل البلاغ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            
            _buildDetailItem(
              context,
              icon: Icons.tag,
              label: 'رقم التتبع',
              value: report.trackingNumber ?? 'غير متوفر',
              isSelectable: true,
            ),
            
            _buildDetailItem(
              context,
              icon: Icons.link,
              label: 'الرابط',
              value: report.link,
              isSelectable: true,
            ),
            
            _buildDetailItem(
              context,
              icon: Icons.category,
              label: 'نوع التهديد',
              value: report.category,
            ),
            
            _buildDetailItem(
              context,
              icon: Icons.speed,
              label: 'درجة الخطورة',
              value: _getSeverityLabel(report.severity),
              valueColor: _getSeverityColor(context, report.severity),
            ),
            
            _buildDetailItem(
              context,
              icon: Icons.info,
              label: 'الحالة',
              value: _statusConfig(report.status).$2,
              valueColor: _statusConfig(report.status).$1,
            ),
            
            _buildDetailItem(
              context,
              icon: Icons.calendar_today,
              label: 'تاريخ الإبلاغ',
              value: '${report.reportDate.year}/${report.reportDate.month.toString().padLeft(2, '0')}/${report.reportDate.day.toString().padLeft(2, '0')}',
            ),
            
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailItem(
                context,
                icon: Icons.description,
                label: 'وصف إضافي',
                value: report.description,
              ),
            ],
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // عنصر تفصيلي في عرض التفاصيل
  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isSelectable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                if (isSelectable)
                  SelectableText(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ تأكيد حذف بلاغ فردي مع ميزة التراجع
  Future<void> _confirmDeleteReport(BuildContext context, ReportModel report, ReportNotifier notifier) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text('حذف البلاغ'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف البلاغ رقم: ${report.trackingNumber ?? report.link.substring(0, 20)}...؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        // حفظ البلاغ المحذوف للتراجع
        _lastDeletedReport = report;
        
        // إلغاء أي تايمر سابق
        _undoTimer?.cancel();
        
        // حذف البلاغ محلياً فقط
        notifier.deleteReportLocally(report.id);
        
        if (!context.mounted) return;
        
        final linkPreview = report.link.length > 30 
            ? '${report.link.substring(0, 30)}...' 
            : report.link;
        
        // إظهار رسالة نجاح الحذف مع زر التراجع (5 ثواني)
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'تم حذف البلاغ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        linkPreview,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'سيتم إغلاق هذه الرسالة بعد 5 ثواني',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: () {
                // إعادة البلاغ المحذوف
                if (_lastDeletedReport != null) {
                  notifier.addReportLocally(_lastDeletedReport!);
                  _lastDeletedReport = null;
                  _undoTimer?.cancel();
                  
                  // إظهار رسالة تأكيد التراجع
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم التراجع عن الحذف'),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        );
        
        // تايمر لمسح البلاغ المحفوظ بعد انتهاء مدة التراجع
        _undoTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _lastDeletedReport = null;
            });
          }
        });
        
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

  // ✅ تأكيد حذف جميع البلاغات مع ميزة التراجع
  Future<void> _confirmClearAllReports(BuildContext context, ReportNotifier notifier) async {
    final currentReports = ref.read(reportProvider).value ?? [];
    
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('حذف جميع البلاغات'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل أنت متأكد من حذف جميع البلاغات السابقة؟'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم حذف ${currentReports.length} بلاغ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      try {
        // حفظ البلاغات المحذوفة للتراجع
        final deletedReports = List<ReportModel>.from(currentReports);
        
        // حذف جميع البلاغات محلياً
        notifier.clearAllReportsLocally();
        
        if (!context.mounted) return;
        
        // إظهار رسالة نجاح الحذف مع زر التراجع (5 ثواني)
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تم حذف جميع البلاغات',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'سيتم إغلاق هذه الرسالة بعد 5 ثواني',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: () {
                // إعادة جميع البلاغات المحذوفة
                for (var report in deletedReports) {
                  notifier.addReportLocally(report);
                }
                
                // إظهار رسالة تأكيد التراجع
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم التراجع عن حذف ${deletedReports.length} بلاغ'),
                    backgroundColor: Colors.blue,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
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

  Widget _buildLinkField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الرابط المشبوه *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _linkController,
          focusNode: _linkFocusNode,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'https://example.com',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            prefixIcon: Icon(
              Icons.link,
              color: _linkFocusNode.hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.clear,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _linkController.clear(),
            ),
          ),
          textDirection: TextDirection.ltr,
          onTap: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildCategoryField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع التهديد *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                hint: Text(
                  'اختر نوع التهديد',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'درجة الخطورة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: _severityLevels.map((level) {
            final isSelected = _selectedSeverity == level['value'];
            final color = _getSeverityColor(context, level['value']);
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSeverity = level['value'];
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color : color.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        level['value'].toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.surface
                              : color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        level['label'],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Theme.of(context).colorScheme.surface
                              : color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وصف إضافي (اختياري)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          maxLines: 4,
          maxLength: 500,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'أضف أي تفاصيل إضافية عن الرابط...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            counterStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          onTap: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitReport,
        icon: const Icon(Icons.send),
        label: _isSubmitting
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                ),
              )
            : const Text(
                'إرسال البلاغ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelines(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'إرشادات الإبلاغ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGuidelineItem(context, 'تأكد من صحة الرابط قبل الإبلاغ'),
          _buildGuidelineItem(context, 'الإبلاغ الكاذب قد يعرضك للمساءلة'),
          _buildGuidelineItem(context, 'سيتم مراجعة البلاغ خلال 24 ساعة'),
          _buildGuidelineItem(context, 'يمكنك متابعة حالة البلاغ عبر رقم التتبع'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lastError,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              reportNotifier.clearError();
              setState(() {});
            },
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cfg.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cfg.$1.withValues(alpha: 0.3)),
      ),
      child: Text(
        cfg.$2,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: cfg.$1,
        ),
      ),
    );
  }

  (Color, String) _statusConfig(String? status) {
    switch (status) {
      case 'pending':
        return (const Color(0xFFE67E22), 'قيد المراجعة');
      case 'reviewing':
        return (const Color(0xFF2980B9), 'قيد التحقيق');
      case 'confirmed':
        return (const Color(0xFFC0392B), 'تم التأكيد');
      case 'rejected':
        return (const Color(0xFF7F8C8D), 'مرفوض');
      case 'resolved':
        return (const Color(0xFF27AE60), 'تم الحل');
      default:
        return (const Color(0xFFE67E22), 'قيد المراجعة');
    }
  }

  Future<void> _submitReport() async {
    if (_linkController.text.trim().isEmpty) {
      showSnackBar('يرجى إدخال الرابط المشبوه', Theme.of(context).colorScheme.error);
      return;
    }

    if (_selectedCategory == null) {
      showSnackBar('يرجى اختيار نوع التهديد', Theme.of(context).colorScheme.error);
      return;
    }

    if (!_isValidUrl(_linkController.text)) {
      showSnackBar('الرابط غير صحيح', Theme.of(context).colorScheme.error);
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
        showSuccessDialog(ref);
        clearForm();
      }
    } else if (mounted) {
      showSnackBar(
        reportNotifier.lastError ?? 'فشل إرسال البلاغ', 
        Theme.of(context).colorScheme.error
      );
    }
  }

  bool _isValidUrl(String url) {
    final urlPattern = r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$';
    final regex = RegExp(urlPattern, caseSensitive: false);
    return regex.hasMatch(url);
  }

  void clearForm() {
    _linkController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedSeverity = 3;
    });
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showSuccessDialog(WidgetRef ref) {
    final reportState = ref.read(reportProvider);
    final reports = reportState.value ?? [];
    final lastReport = reports.isNotEmpty ? reports.first : null;
    
    final trackingNumber = lastReport?.trackingNumber ?? 'جاري إنشاء رقم التتبع';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'تم استلام البلاغ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.tertiary,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'شكراً لك على المساهمة في حماية المجتمع',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'رقم تتبع البلاغ:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    trackingNumber,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إغلاق',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}