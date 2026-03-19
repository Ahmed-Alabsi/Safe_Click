import 'package:dio/dio.dart';
import 'package:safeclik/core/network/api_client.dart';

class ScanApi {
  final ApiClient _client;

  ScanApi(this._client);

  Future<Map<String, dynamic>> scanLink(String link, {String scanLevel = 'deep'}) async {
    try {
      final response = await _client.dio.post('/scans/scan/', data: {'link': link, 'scan_level': scanLevel}, 
      options: Options(receiveTimeout: const Duration(seconds: 60)));
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getScanHistory() async {
    try {
      final response = await _client.dio.get('/scans/history/');
      return response.data;
    } catch (e) {
      final err = _client.handleDioError(e);
      err['history'] = [];
      return err;
    }
  }

  Future<Map<String, dynamic>> getScanDetail(String scanId) async {
    try {
      final response = await _client.dio.get('/scans/history/$scanId/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteScan(String scanId) async {
    try {
      final response = await _client.dio.post('/scans/history/$scanId/delete/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> clearHistory() async {
    try {
      final response = await _client.dio.post('/scans/history/clear-all/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getScanStats() async {
    try {
      final response = await _client.dio.get('/scans/stats/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> restoreScan(String scanId) async {
    try {
      final response = await _client.dio.post('/scans/history/$scanId/restore/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> restoreScansBulk(List<String> scanIds) async {
    try {
      final response = await _client.dio.post(
        '/scans/history/restore-bulk/',
        data: {'scan_ids': scanIds},
      );
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }
}
