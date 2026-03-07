// lib/features/scan/data/datasources/remote_scan_datasource.dart
//
// Thin wrapper around ApiService for scan-related endpoints.
// Does NOT modify ApiService logic.

import 'package:safeclik/core/network/api_service.dart';

class RemoteScanDataSource {
  final ApiService _apiService;
  RemoteScanDataSource(this._apiService);

  Future<Map<String, dynamic>> scanLink(String link) =>
      _apiService.scanLink(link);

  Future<Map<String, dynamic>> getScanHistory() =>
      _apiService.getScanHistory();

  Future<Map<String, dynamic>> deleteScan(String id) =>
      _apiService.deleteScan(id);

  Future<Map<String, dynamic>> clearHistory() =>
      _apiService.clearHistory();
}
