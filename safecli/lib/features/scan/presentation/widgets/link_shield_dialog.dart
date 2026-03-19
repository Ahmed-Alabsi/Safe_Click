// lib/features/scan/presentation/widgets/link_shield_dialog.dart
// واجهة الدرع الذكي لاعتراض وفحص الروابط

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safeclik/features/scan/data/models/scan_result.dart';

enum ShieldState { scanning, safe, suspicious, dangerous }

class LinkShieldDialog extends StatefulWidget {
  final String link;
  final Future<ScanResult?> Function(String link) onScan;

  const LinkShieldDialog({
    super.key,
    required this.link,
    required this.onScan,
  });

  /// يعرض الحوار ويعيد النتيجة
  static Future<ScanResult?> show(
    BuildContext context, {
    required String link,
    required Future<ScanResult?> Function(String link) onScan,
  }) {
    return showDialog<ScanResult?>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => LinkShieldDialog(link: link, onScan: onScan),
    );
  }

  @override
  State<LinkShieldDialog> createState() => _LinkShieldDialogState();
}

class _LinkShieldDialogState extends State<LinkShieldDialog>
    with SingleTickerProviderStateMixin {
  ShieldState _state = ShieldState.scanning;
  ScanResult? _result;
  String? _errorMessage;
  late AnimationController _pulseController;

  // Platform channel لإخفاء التطبيق
  static const _platform = MethodChannel('com.example.safecli/app');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startScan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// إخفاء التطبيق والعودة للتطبيق السابق
  Future<void> _minimizeApp() async {
    try {
      await _platform.invokeMethod('moveTaskToBack');
    } catch (e) {
      // Fallback: إذا فشل الـ MethodChannel، استخدم SystemNavigator
      debugPrint('⚠️ moveTaskToBack failed, using SystemNavigator: $e');
      SystemNavigator.pop();
    }
  }

  Future<void> _startScan() async {
    try {
      debugPrint('🛡️ [Shield] بدء فحص الرابط: ${widget.link}');
      
      final result = await widget.onScan(widget.link);

      debugPrint('🛡️ [Shield] نتيجة الفحص: safe=${result?.safe}, score=${result?.score}, message=${result?.message}');

      if (!mounted) return;

      if (result == null) {
        debugPrint('🛡️ [Shield] النتيجة فارغة - عرض تحذير');
        setState(() {
          _state = ShieldState.suspicious;
          _errorMessage = 'تعذر فحص الرابط';
        });
        return;
      }

      _result = result;

      if (result.safe == true) {
        // ✅ آمن → فتح تلقائي
        debugPrint('🛡️ [Shield] ✅ الرابط آمن - فتح تلقائي');
        setState(() => _state = ShieldState.safe);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        await _openLink(widget.link);
        if (mounted) {
          Navigator.of(context).pop(result);
          _minimizeApp();
        }
      } else if (result.safe == false) {
        // 🚫 خطير
        debugPrint('🛡️ [Shield] 🚫 الرابط خطير - عرض تحذير');
        setState(() => _state = ShieldState.dangerous);
      } else {
        // ⚠️ مشبوه
        debugPrint('🛡️ [Shield] ⚠️ الرابط مشبوه - عرض تحذير');
        setState(() => _state = ShieldState.suspicious);
      }
    } catch (e) {
      debugPrint('🛡️ [Shield] ❌ خطأ في الفحص: $e');
      if (!mounted) return;
      setState(() {
        _state = ShieldState.suspicious;
        _errorMessage = 'حدث خطأ أثناء الفحص';
      });
    }
  }

  Future<void> _openLink(String url) async {
    try {
      String finalUrl = url;
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }
      final uri = Uri.parse(finalUrl);
      debugPrint('🛡️ [Shield] فتح الرابط: $uri');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('❌ فشل فتح الرابط: $e');
    }
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(theme),
            const SizedBox(height: 16),
            _buildTitle(theme),
            const SizedBox(height: 8),
            _buildDomainChip(theme),
            const SizedBox(height: 12),
            _buildMessage(theme),
            if (_state != ShieldState.scanning) ...[
              const SizedBox(height: 20),
              _buildActions(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    switch (_state) {
      case ShieldState.scanning:
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.15),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      case ShieldState.safe:
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.verified_user_rounded, size: 40, color: Colors.green),
        );
      case ShieldState.suspicious:
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
        );
      case ShieldState.dangerous:
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.gpp_bad_rounded, size: 40, color: Colors.red),
        );
    }
  }

  Widget _buildTitle(ThemeData theme) {
    String title;
    Color color;
    switch (_state) {
      case ShieldState.scanning:
        title = 'جاري فحص الرابط...';
        color = theme.colorScheme.primary;
        break;
      case ShieldState.safe:
        title = 'الرابط آمن ✅';
        color = Colors.green;
        break;
      case ShieldState.suspicious:
        title = 'تحذير: رابط مشبوه ⚠️';
        color = Colors.orange;
        break;
      case ShieldState.dangerous:
        title = '🚫 رابط خطير!';
        color = Colors.red;
        break;
    }
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDomainChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _extractDomain(widget.link),
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant,
          fontFamily: 'monospace',
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMessage(ThemeData theme) {
    String msg;
    switch (_state) {
      case ShieldState.scanning:
        msg = 'يتم الآن تحليل الرابط والتحقق من سلامته...';
        break;
      case ShieldState.safe:
        msg = 'جاري فتح الرابط...';
        break;
      case ShieldState.suspicious:
        msg = _errorMessage ?? _result?.message ?? 'هذا الرابط مشبوه وقد يحتوي على محتوى ضار. هل تريد المتابعة على مسؤوليتك؟';
        break;
      case ShieldState.dangerous:
        msg = _result?.message ?? 'تم اكتشاف تهديدات أمنية في هذا الرابط. يُنصح بعدم فتحه.';
        break;
    }
    return Text(
      msg,
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActions(ThemeData theme) {
    switch (_state) {
      case ShieldState.scanning:
      case ShieldState.safe:
        return const SizedBox.shrink();
      case ShieldState.suspicious:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await _openLink(widget.link);
                if (mounted) {
                  Navigator.of(context).pop(_result);
                  _minimizeApp();
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('فتح على مسؤوليتي'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(_result);
                _minimizeApp();
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('إلغاء'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ],
        );
      case ShieldState.dangerous:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عرض عدد التهديدات إن وجدت
            if (_result?.threatsCount != null && _result!.threatsCount! > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bug_report, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_result!.threatsCount} تهديد تم اكتشافه',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(_result);
                _minimizeApp();
              },
              icon: const Icon(Icons.block, size: 18),
              label: const Text('حظر الرابط'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_result);
                _minimizeApp();
              },
              child: Text(
                'إلغاء',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        );
    }
  }
}
