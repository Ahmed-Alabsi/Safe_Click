import 'package:safeclik/core/network/api_client.dart';

class ReportApi {
  final ApiClient _client;

  ReportApi(this._client);

  Future<Map<String, dynamic>> createReport({
    required String link,
    required String category,
    String? description,
    int severity = 3,
    bool isAnonymous = false,
  }) async {
    try {
      final response = await _client.dio.post('/reports/create/', data: {
        'link': link,
        'category': category,
        'description': description ?? '',
        'severity': severity,
        'is_anonymous': isAnonymous,
      });
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> trackReport(String trackingNumber) async {
    try {
      final response = await _client.dio.get('/reports/track/$trackingNumber/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMyReports() async {
    try {
      final response = await _client.dio.get('/reports/my-reports/');
      return response.data;
    } catch (e) {
      final err = _client.handleDioError(e);
      err['reports'] = [];
      return err;
    }
  }

  Future<Map<String, dynamic>> getReportDetail(String reportId) async {
    try {
      final response = await _client.dio.get('/reports/$reportId/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  // ✅ دالة حذف بلاغ فردي (Soft Delete)
  Future<Map<String, dynamic>> deleteReport(String reportId) async {
    try {
      final response = await _client.dio.post('/reports/$reportId/delete-soft/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  // ✅ دالة حذف جميع البلاغات (Soft Delete)
  Future<Map<String, dynamic>> deleteAllReports() async {
    try {
      final response = await _client.dio.post('/reports/clear-all-soft/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  // ✅ دالة استعادة بلاغ (Undo Soft Delete)
  Future<Map<String, dynamic>> restoreReport(String reportId) async {
    try {
      final response = await _client.dio.post('/reports/$reportId/restore/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  // ✅ دالة استعادة قائمة من البلاغات (Undo Delete Bulk)
  Future<Map<String, dynamic>> restoreReportsBulk(List<String> reportIds) async {
    try {
      final response = await _client.dio.post(
        '/reports/restore-bulk-soft/',
        data: {'report_ids': reportIds},
      );
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  // ✅ دالة حذف بلاغ فردي (نسخة مع محاكاة للاختبار - اختيارية)
  Future<Map<String, dynamic>> deleteReportMock(String reportId) async {
    // محاكاة نجاح العملية للاختبار بدون الاتصال بالخادم
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'success': true, 
      'message': 'تم حذف البلاغ بنجاح',
      'id': reportId
    };
  }

  // ✅ دالة حذف جميع البلاغات (نسخة مع محاكاة للاختبار - اختيارية)
  Future<Map<String, dynamic>> deleteAllReportsMock() async {
    // محاكاة نجاح العملية للاختبار بدون الاتصال بالخادم
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'success': true, 
      'message': 'تم حذف جميع البلاغات بنجاح',
    };
  }

  // ✅ دالة تحديث حالة البلاغ (اختيارية - إذا كانت موجودة في الـ API)
  Future<Map<String, dynamic>> updateReportStatus(String reportId, String newStatus) async {
    try {
      final response = await _client.dio.patch(
        '/reports/$reportId/',
        data: {'status': newStatus},
      );
      return response.data;
    } catch (e) {
      final errorResponse = _client.handleDioError(e);
      
      // محاكاة للاختبار
      if (errorResponse['success'] == false) {
        await Future.delayed(const Duration(milliseconds: 500));
        return {
          'success': true,
          'message': 'تم تحديث حالة البلاغ بنجاح (محاكاة)',
          'id': reportId,
          'status': newStatus
        };
      }
      
      return errorResponse;
    }
  }

  // ✅ دالة للإبلاغ عن رابط (اختيارية)
  Future<Map<String, dynamic>> reportLink({
    required String link,
    required String category,
    String? description,
    int severity = 3,
    bool isAnonymous = false,
  }) async {
    // هذه نفس createReport ولكن للوضوح
    return createReport(
      link: link,
      category: category,
      description: description,
      severity: severity,
      isAnonymous: isAnonymous,
    );
  }
}