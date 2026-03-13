import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safeclik/features/scan/data/models/scan_result.dart';

class ResultScreen extends StatelessWidget {
  final ScanResult scanResult;

  const ResultScreen({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSafe = scanResult.safe;
    final Color statusColor = isSafe == true
        ? theme.colorScheme.tertiary
        : isSafe == false
            ? theme.colorScheme.error
            : theme.colorScheme.secondary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, statusColor),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildResultHeader(context, statusColor),
                  const SizedBox(height: 20),
                  _buildLinkCard(context, statusColor),
                  const SizedBox(height: 20),
                  _buildScoreCard(context, statusColor),
                  const SizedBox(height: 20),
                  _buildDetailsCard(context, statusColor),
                  if (scanResult.ipAddress != null || scanResult.domain != null) ...[
                    const SizedBox(height: 20),
                    _buildTechnicalInfo(context, statusColor),
                  ],
                  const SizedBox(height: 30),
                  _buildActionButtons(context, statusColor),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);
    final isSafe = scanResult.safe;
    
    String statusText = isSafe == true
        ? 'آمن'
        : isSafe == false
            ? 'خطير'
            : 'مشبوه';

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: statusColor,
      foregroundColor: theme.colorScheme.onPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSafe == true
                    ? Icons.check_circle_rounded
                    : isSafe == false
                        ? Icons.dangerous_rounded
                        : Icons.warning_rounded,
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'نتيجة الفحص: $statusText',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.centerRight,
                  radius: 1.2,
                  colors: [
                    statusColor,
                    statusColor.withValues(alpha: 0.7),
                    statusColor.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Transform.rotate(
                angle: 0.3,
                child: Icon(
                  isSafe == true
                      ? Icons.check_circle_rounded
                      : isSafe == false
                          ? Icons.dangerous_rounded
                          : Icons.warning_rounded,
                  size: 200,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  isSafe == true
                      ? Icons.security_rounded
                      : isSafe == false
                          ? Icons.error_rounded
                          : Icons.info_rounded,
                  size: 150,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareResult(context),
            tooltip: 'مشاركة',
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultHeader(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);
    final isSafe = scanResult.safe;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.1),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  statusColor,
                  statusColor.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isSafe == true
                  ? Icons.check_circle_rounded
                  : isSafe == false
                      ? Icons.dangerous_rounded
                      : Icons.warning_rounded,
              color: theme.colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scanResult.message,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSafe == true
                      ? 'يمكنك فتح الرابط بأمان ✓'
                      : isSafe == false
                          ? 'ننصحك بعدم فتح هذا الرابط ⚠'
                          : 'تعامل مع هذا الرابط بحذر',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'الرابط المفحوص',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: SelectableText(
                scanResult.link,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(scanResult.timestamp),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'ID: ${scanResult.id.length > 8 ? scanResult.id.substring(0, 8) : scanResult.id}...',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'مستوى الأمان',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.2),
                        statusColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${scanResult.score}%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: scanResult.score / 100,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.8),
                          statusColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreChip(context, 'آمن', scanResult.safe == true, theme.colorScheme.tertiary),
                _buildScoreChip(context, 'مشبوه', scanResult.safe == null, theme.colorScheme.secondary),
                _buildScoreChip(context, 'خطير', scanResult.safe == false, theme.colorScheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(BuildContext context, String label, bool isActive, Color color) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? color : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? color : theme.colorScheme.outline.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isActive ? color : theme.colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.info_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'تفاصيل الفحص',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...scanResult.details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildDetailItem(context, detail),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String detail) {
    final theme = Theme.of(context);
    final bool isPositive = detail.contains('✓') || detail.contains('آمن') || detail.contains('صالح');
    final bool isWarning = detail.contains('⚠') || detail.contains('تحذير') || detail.contains('مشبوه');
    final bool isError = detail.contains('✗') || detail.contains('خطأ') || detail.contains('ضار');
    
    Color itemColor = isError 
        ? theme.colorScheme.error 
        : isWarning 
            ? theme.colorScheme.secondary 
            : isPositive
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant;

    IconData iconData = isError 
        ? Icons.cancel_rounded 
        : isWarning 
            ? Icons.warning_amber_rounded 
            : isPositive
                ? Icons.check_circle_rounded
                : Icons.info_rounded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: itemColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            size: 18,
            color: itemColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalInfo(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.dns_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'معلومات تقنية',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  if (scanResult.domain != null)
                    _buildInfoRow(context, 'النطاق', scanResult.domain!, Icons.language_rounded, statusColor),
                  if (scanResult.domain != null && scanResult.ipAddress != null)
                    const SizedBox(height: 12),
                  if (scanResult.ipAddress != null)
                    _buildInfoRow(context, 'عنوان IP', scanResult.ipAddress!, Icons.computer_rounded, statusColor),
                  if ((scanResult.domain != null || scanResult.ipAddress != null) && scanResult.responseTime > 0)
                    const SizedBox(height: 12),
                  if (scanResult.responseTime > 0)
                    _buildInfoRow(context, 'زمن الاستجابة', '${scanResult.responseTime.toStringAsFixed(2)} ثانية', Icons.timer_rounded, statusColor),
                  if (scanResult.responseTime > 0 && scanResult.threatsCount != null)
                    const SizedBox(height: 12),
                  if (scanResult.threatsCount != null)
                    _buildInfoRow(context, 'عدد التهديدات', scanResult.threatsCount.toString(), Icons.warning_rounded, 
                      scanResult.threatsCount! > 0 ? theme.colorScheme.error : theme.colorScheme.tertiary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _navigateToPage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    scanResult.safe == false 
                        ? Icons.warning_rounded 
                        : Icons.open_in_browser_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    scanResult.safe == false ? 'فتح على مسؤوليتي' : 'فتح الرابط',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outline,
                width: 1.5,
              ),
            ),
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: const BorderSide(color: Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'رجوع',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToPage(BuildContext context) async {
    String url = scanResult.link;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    if (scanResult.safe == false) {
      final shouldProceed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'تحذير!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'هذا الرابط قد يكون خطيراً. هل أنت متأكد من المتابعة؟',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Text('متابعة'),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      if (shouldProceed != true) return;
    }

    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onError.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.onError,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('لا يمكن فتح هذا الرابط'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _shareResult(BuildContext context) {
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_rounded,
                color: theme.colorScheme.onPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('سيتم إضافة ميزة المشاركة قريباً'),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

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
}