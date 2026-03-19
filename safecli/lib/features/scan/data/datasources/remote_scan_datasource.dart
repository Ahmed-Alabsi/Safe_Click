// lib/features/scan/data/datasources/remote_scan_datasource.dart
//
// Thin wrapper around ApiService for scan-related endpoints.
// Does NOT modify ApiService logic.

import 'package:safeclik/core/network/scan_api.dart';

class RemoteScanDataSource {
  final ScanApi _scanApi;
  RemoteScanDataSource(this._scanApi);

  Future<Map<String, dynamic>> scanLink(String link, {String scanLevel = 'deep'}) =>
      _scanApi.scanLink(link, scanLevel: scanLevel);

  Future<Map<String, dynamic>> getScanHistory() =>
      _scanApi.getScanHistory();

  Future<Map<String, dynamic>> deleteScan(String id) =>
      _scanApi.deleteScan(id);

  Future<Map<String, dynamic>> clearHistory() =>
      _scanApi.clearHistory();
}
