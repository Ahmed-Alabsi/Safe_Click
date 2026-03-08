import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/core/network/report_api.dart';
import 'package:safeclik/features/report/data/models/report_model.dart';
import 'package:safeclik/core/di/di.dart';
import 'package:flutter/foundation.dart';

final reportProvider = AsyncNotifierProvider<ReportNotifier, List<ReportModel>>(
  () => ReportNotifier(),
);

class ReportNotifier extends AsyncNotifier<List<ReportModel>> {
  final ReportApi _reportApi = sl<ReportApi>();
  String? _lastError;
  bool _isReporting = false;

  String? get lastError => _lastError;
  bool get isReporting => _isReporting;

  @override
  Future<List<ReportModel>> build() async {
    return _fetchMyReports();
  }

  Future<List<ReportModel>> _fetchMyReports() async {
    try {
      final response = await _reportApi.getMyReports();
      if (response['success'] == true) {
        final List<dynamic> reportsJson = response['reports'] ?? [];
        return reportsJson.map((json) => ReportModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب البلاغات: $e');
    }
    return [];
  }

  Future<bool> submitReport({
    required String link,
    required String category,
    required String description,
    required int severity,
    required String reporterName,
  }) async {
    // Phase B: Multiple Request Protection
    if (_isReporting || state.isLoading) return false;

    _isReporting = true;
    _lastError = null;
    
    // We notify UI that reporting started by setting loading if needed or just updating UI
    
    try {
      debugPrint('🔵 إرسال بلاغ: $link - $category');
      
      final response = await _reportApi.createReport(
        link: link,
        category: category,
        description: description,
        severity: severity,
        isAnonymous: reporterName == 'مستخدم مجهول',
      );

      debugPrint('📥 الرد: $response');

      if (response['success'] == true) {
        // Refresh reports
        final updatedReports = await _fetchMyReports();
        state = AsyncValue.data(updatedReports);
        return true;
      } else {
        _lastError = response['message'] ?? 'فشل إرسال البلاغ';
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ: $e');
      _lastError = 'حدث خطأ في الاتصال بالخادم';
      return false;
    } finally {
      _isReporting = false;
    }
  }

  void clearError() {
    _lastError = null;
  }
}
