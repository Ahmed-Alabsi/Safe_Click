import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/scan/presentation/controllers/scan_notifier.dart';
import 'package:safeclik/features/scan/presentation/pages/result_screen.dart';
import 'package:safeclik/features/scan/data/models/scan_result.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 🔍 متغيرات البحث
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // 🗑️ متغيرات للتراجع عن الحذف الفردي
  ScanResult? _lastDeletedScan;

  // 🗑️ متغيرات للتراجع عن حذف الكل
  List<ScanResult>? _lastDeletedAllScans;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      ref.read(historyFilterProvider.notifier).state = _tabController.index;
      ref.read(historySearchProvider.notifier).state = '';
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    ref.read(historySearchProvider.notifier).state = '';
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _updateSearch(String value) {
    ref.read(historySearchProvider.notifier).state = value;
  }

  void _changeTab(int index) {
    if (index >= 0 && index < _tabController.length) {
      _tabController.animateTo(index);
      ref.read(historyFilterProvider.notifier).state = index;
      ref.read(historySearchProvider.notifier).state = '';
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    }
  }

  // 🔄 دالة التراجع عن الحذف الفردي
  void _undoDelete() {
    if (_lastDeletedScan == null) return;
    
    try {
      final scanToRestore = _lastDeletedScan!;
      // Restore locally
      ref.read(scanNotifierProvider.notifier).addScanResult(scanToRestore);
      
      // Background sync restore
      ref.read(scanNotifierProvider.notifier).restoreScanResult(scanToRestore.id);
      
      ScaffoldMessenger.of(context).clearSnackBars();
      
      _lastDeletedScan = null;
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

  // 🔄 دالة التراجع عن مسح السجل
  void _undoDeleteAll() {
    if (_lastDeletedAllScans == null) return;
    
    try {
      // Restore locally
      ref.read(scanNotifierProvider.notifier).addScansLocally(_lastDeletedAllScans!);
      
      // Background sync restore
      final ids = _lastDeletedAllScans!.map((s) => s.id).toList();
      ref.read(scanNotifierProvider.notifier).restoreScansBulk(ids);
      
      ScaffoldMessenger.of(context).clearSnackBars();
      
      _lastDeletedAllScans = null;
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
    final scanHistory = ref.watch(scanNotifierProvider).scanHistory;
    final filteredHistory = ref.watch(filteredHistoryProvider);
    final theme = Theme.of(context);
    final searchQuery = ref.watch(historySearchProvider);
    final selectedIndex = ref.watch(historyFilterProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(scanNotifierProvider.notifier).refreshHistory();
            },
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ✅ Sliver للرأس مع تأثيرات
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: _isSearching 
                        ? _buildSearchBar(theme)
                        : _buildHeader(theme, scanHistory),
                  ),
                ),

                // ✅ Sliver للتبويبات
                if (!_isSearching)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildTabs(theme, scanHistory, selectedIndex),
                    ),
                  ),

                // ✅ عرض نتائج البحث
                if (_isSearching && searchQuery.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSearchResultsHeader(theme, filteredHistory, searchQuery),
                  ),

                // ✅ المحتوى الرئيسي
                filteredHistory.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(theme, selectedIndex, searchQuery),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final scan = filteredHistory[index];
                              return _buildHistoryCard(context, scan, ref);
                            },
                            childCount: filteredHistory.length,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ تبويبات محسنة
  Widget _buildTabs(ThemeData theme, List<ScanResult> scanHistory, int selectedIndex) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(
            index: 0,
            selectedIndex: selectedIndex,
            icon: Icons.list_alt_rounded,
            label: 'الكل',
            count: scanHistory.length,
            color: theme.colorScheme.primary,
          ),
          _buildTabItem(
            index: 1,
            selectedIndex: selectedIndex,
            icon: Icons.check_circle_rounded,
            label: 'آمن',
            count: scanHistory.where((s) => s.safe == true).length,
            color: theme.colorScheme.tertiary,
          ),
          _buildTabItem(
            index: 2,
            selectedIndex: selectedIndex,
            icon: Icons.warning_amber_rounded,
            label: 'مشبوه',
            count: scanHistory.where((s) => s.safe == null).length,
            color: theme.colorScheme.secondary,
          ),
          _buildTabItem(
            index: 3,
            selectedIndex: selectedIndex,
            icon: Icons.dangerous_rounded,
            label: 'خطر',
            count: scanHistory.where((s) => s.safe == false).length,
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  // ✅ عنصر التبويب
  Widget _buildTabItem({
    required int index,
    required int selectedIndex,
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => _changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : color.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.2)
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    count.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✅ رأس محسن
  Widget _buildHeader(ThemeData theme, List<ScanResult> scanHistory) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.history_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سجل الفحوصات',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${scanHistory.length} فحص',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            if (scanHistory.isNotEmpty)
              _buildIconButton(
                icon: Icons.search_rounded,
                color: theme.colorScheme.primary,
                onPressed: _startSearch,
                tooltip: 'بحث',
              ),
            if (scanHistory.isNotEmpty)
              const SizedBox(width: 8),
            if (scanHistory.isNotEmpty)
              _buildIconButton(
                icon: Icons.delete_sweep_rounded,
                color: theme.colorScheme.error,
                onPressed: () => _confirmClearHistory(context, ref),
                tooltip: 'مسح الكل',
              ),
          ],
        ),
      ],
    );
  }

  // ✅ زر أيقونة محسن
  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ شريط بحث محسن
  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: '🔍 ابحث عن رابط...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                suffixIcon: _buildSearchCloseButton(theme),
              ),
              onChanged: _updateSearch,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ زر إغلاق البحث
  Widget _buildSearchCloseButton(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          Icons.close_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 18,
        ),
        onPressed: _stopSearch,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  // ✅ رأس نتائج البحث المحسن
  Widget _buildSearchResultsHeader(ThemeData theme, List<ScanResult> filteredHistory, String searchQuery) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF667EEA)),
          ),
          const SizedBox(width: 8),
          Text(
            'نتائج البحث: ',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${filteredHistory.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          if (filteredHistory.isEmpty && searchQuery.isNotEmpty)
            _buildCancelSearchButton(theme),
        ],
      ),
    );
  }

  // ✅ زر إلغاء البحث المحسن
  Widget _buildCancelSearchButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.error.withValues(alpha: 0.1),
            theme.colorScheme.error.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _stopSearch,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'إلغاء البحث',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ بطاقة التاريخ المحسنة
  Widget _buildHistoryCard(BuildContext context, ScanResult scan, WidgetRef ref) {
    final isSafe = scan.safe;
    final theme = Theme.of(context);
    final Color statusColor = isSafe == true
        ? theme.colorScheme.tertiary
        : isSafe == false
            ? theme.colorScheme.error
            : theme.colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultScreen(scanResult: scan),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor.withValues(alpha: 0.1),
                        statusColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSafe == true
                        ? Icons.check_circle_rounded
                        : isSafe == false
                            ? Icons.dangerous_rounded
                            : Icons.warning_rounded,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.security, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${scan.score}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(scan.timestamp),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _confirmDeleteScan(context, scan, ref),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ باقي الدوال كما هي (لم يتم تغييرها)
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final scanDate = DateTime(date.year, date.month, date.day);

    if (scanDate == today) {
      return 'اليوم ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (scanDate == yesterday) {
      return 'أمس ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  IconData _getEmptyIcon(int selectedIndex) {
    switch (selectedIndex) {
      case 0: return Icons.history_outlined;
      case 1: return Icons.check_circle_outline;
      case 2: return Icons.warning_amber_outlined;
      case 3: return Icons.dangerous_outlined;
      default: return Icons.history_outlined;
    }
  }

  Color _getEmptyIconColor(ThemeData theme, int selectedIndex) {
    switch (selectedIndex) {
      case 1: return theme.colorScheme.tertiary;
      case 2: return theme.colorScheme.secondary;
      case 3: return theme.colorScheme.error;
      default: return theme.colorScheme.primary;
    }
  }

  String _getEmptyMessage(int selectedIndex) {
    switch (selectedIndex) {
      case 0: return 'لا يوجد سجل فحوصات';
      case 1: return 'لا توجد روابط آمنة';
      case 2: return 'لا توجد روابط مشبوهة';
      case 3: return 'لا توجد روابط خطرة';
      default: return '';
    }
  }

  String _getEmptySubMessage(int selectedIndex) {
    switch (selectedIndex) {
      case 0: return 'قم بفحص رابط جديد ليظهر هنا';
      case 1: return 'جميع الروابط التي قمت بفحصها آمنة';
      case 2: return 'لم تصادف أي روابط مشبوهة حتى الآن';
      case 3: return 'لم تصادف أي روابط خطرة حتى الآن';
      default: return '';
    }
  }

  Widget _buildEmptyState(ThemeData theme, int selectedIndex, String searchQuery) {
    if (_isSearching && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد نتائج للبحث',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'حاول استخدام كلمات بحث مختلفة',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            _buildCancelSearchButton(theme),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getEmptyIconColor(theme, selectedIndex).withValues(alpha: 0.1),
            ),
            child: Icon(
              _getEmptyIcon(selectedIndex),
              size: 60,
              color: _getEmptyIconColor(theme, selectedIndex).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getEmptyMessage(selectedIndex),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptySubMessage(selectedIndex),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteScan(BuildContext context, ScanResult scan, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text('حذف الفحص'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف الفحص: ${scan.link.length > 30 ? '${scan.link.substring(0, 30)}...' : scan.link}؟'),
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
        _lastDeletedScan = scan;
        
        // 1. Optimistic update
        ref.read(scanNotifierProvider.notifier).removeScanLocally(scan.id);
        
        // 2. Background sync
        ref.read(scanNotifierProvider.notifier).softDeleteScanResult(scan.id);
        
        if (!context.mounted) return;
        
        final linkPreview = scan.link.length > 30 
            ? '${scan.link.substring(0, 30)}...' 
            : scan.link;
        
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
                        'تم الحذف بنجاح',
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
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: _undoDelete,
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
                const SizedBox(width: 12),
                Expanded(child: Text('حدث خطأ أثناء الحذف: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final scanHistory = ref.read(scanNotifierProvider).scanHistory;
    final historyCount = scanHistory.length;
    
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('مسح السجل بالكامل'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل أنت متأكد من مسح جميع الفحوصات السابقة؟'),
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
                      'سيتم مسح $historyCount فحص',
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
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      try {
        _lastDeletedAllScans = List.from(scanHistory);
        
        // 1. Optimistic update
        ref.read(scanNotifierProvider.notifier).clearHistoryLocally();
        _stopSearch();
        
        // 2. Background sync
        ref.read(scanNotifierProvider.notifier).clearUserHistory();
        
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'تم مسح السجل بالكامل',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'تم حذف $historyCount فحص',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: _undoDeleteAll,
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
                const SizedBox(width: 12),
                Expanded(child: Text('حدث خطأ أثناء مسح السجل: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}