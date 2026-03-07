import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safeclik/features/scan/data/models/scan_result.dart';

class ResultScreen extends StatelessWidget {
  final ScanResult scanResult;

  const ResultScreen({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    Color itemColor = scanResult.safe == true ? Theme.of(context).colorScheme.tertiary : scanResult.safe == false ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نتيجة الفحص'),
          centerTitle: true,
          backgroundColor: itemColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareResult(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildResultHeader(context, itemColor),
              const SizedBox(height: 20),
              _buildLinkCard(context),
              const SizedBox(height: 20),
              _buildScoreCard(context, itemColor),
              const SizedBox(height: 20),
              _buildDetailsCard(context),
              const SizedBox(height: 20),
              _buildTechnicalInfo(context),
              const SizedBox(height: 30),
              _buildActionButtons(context, itemColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context, Color itemColor) {
    IconData icon;
    String statusText;
    Color color = itemColor;

    if (scanResult.safe == true) {
      icon = Icons.check_circle_outline;
      statusText = 'الرابط آمن';
    } else if (scanResult.safe == false) {
      icon = Icons.dangerous_outlined;
      statusText = 'الرابط خطير';
    } else {
      icon = Icons.warning_amber_outlined;
      statusText = 'الرابط مشبوه';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scanResult.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'الرابط المفحوص',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: SelectableText(
                scanResult.link,
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تاريخ الفحص: ${_formatDate(scanResult.timestamp)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${scanResult.id.substring(0, 8)}...',
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, Color itemColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'مستوى الأمان',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${scanResult.score}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: itemColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: scanResult.score / 100,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          itemColor.withValues(alpha: 0.7),
                          itemColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreIndicator(context, 'آمن', scanResult.safe == true),
                _buildScoreIndicator(context, 'مشبوه', scanResult.safe == null),
                _buildScoreIndicator(context, 'خطير', scanResult.safe == false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(BuildContext context, String label, bool isActive) {
    Color color = label == 'آمن' ? Theme.of(context).colorScheme.tertiary : 
                  label == 'خطير' ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary;
    
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'تفاصيل الفحص',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ...scanResult.details.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        detail.startsWith('✓') ? Icons.check_circle : 
                        detail.startsWith('⚠') ? Icons.warning : Icons.circle,
                        size: 16,
                        color: detail.startsWith('✓') ? Theme.of(context).colorScheme.tertiary :
                               detail.startsWith('⚠') ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          detail,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfo(BuildContext context) {
    if (scanResult.ipAddress == null && scanResult.domain == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dns, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'معلومات تقنية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (scanResult.domain != null)
              _buildInfoRow(context, 'النطاق:', scanResult.domain!),
            if (scanResult.ipAddress != null)
              _buildInfoRow(context, 'عنوان IP:', scanResult.ipAddress!),
            if (scanResult.responseTime > 0)
              _buildInfoRow(context, 'زمن الاستجابة:', '${scanResult.responseTime.toStringAsFixed(2)} ثانية'),
            if (scanResult.threatsCount != null)
              _buildInfoRow(context, 'عدد التهديدات:', scanResult.threatsCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color itemColor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToPage(context),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('فتح الرابط'),
            style: ElevatedButton.styleFrom(
              backgroundColor: itemColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('رجوع'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
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
          title: const Text('تحذير!'),
          content: const Text('هذا الرابط قد يكون خطيراً. هل أنت متأكد من المتابعة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('متابعة'),
            ),
          ],
        ),
      );

      if (!shouldProceed) return;
    }

    try {
      final Uri uri = Uri.parse(url);
      debugPrint('محاولة فتح الرابط: $uri');
      
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
    } catch (e) {
      debugPrint('خطأ في فتح الرابط: $e');
      
      try {
        final Uri uri = Uri.parse(url.replaceFirst('https://', 'http://'));
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('لا يمكن فتح هذا الرابط. يرجى التحقق من صحة الرابط'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _shareResult(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة ميزة المشاركة قريباً'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
