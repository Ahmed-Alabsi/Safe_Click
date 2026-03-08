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
}
