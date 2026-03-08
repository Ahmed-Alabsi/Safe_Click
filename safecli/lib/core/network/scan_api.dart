import 'package:dio/dio.dart';
import 'package:safeclik/core/network/api_client.dart';

class ScanApi {
  final ApiClient _client;

  ScanApi(this._client);

  Future<Map<String, dynamic>> scanLink(String link) async {
    try {
      final response = await _client.dio.post('/scans/scan/', data: {'link': link}, 
      options: Options(receiveTimeout: const Duration(seconds: 30)));
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
      final response = await _client.dio.delete('/scans/history/$scanId/delete/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> clearHistory() async {
    try {
      final response = await _client.dio.delete('/scans/history/clear/');
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
}
