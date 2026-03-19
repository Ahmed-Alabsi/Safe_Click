// lib/features/scan/domain/repositories/scan_repository.dart

import '../entities/scan_entity.dart';

abstract class ScanRepository {
  /// Scan a URL. Returns a [ScanEntity] or null on unrecoverable failure.
  Future<ScanEntity?> scanLink(String link, {String scanLevel = 'deep'});

  /// Fetch scan history for current user (excludes soft-deleted items)
  Future<List<ScanEntity>> getScanHistory(String? userId);

  /// Sync history from remote server and persist locally.
  Future<List<ScanEntity>> syncHistoryFromRemote(String? userId);

  /// Soft delete a scan record (hide from user only)
  Future<bool> softDeleteScan(String id);

  /// Clear history for user (soft delete all)
  Future<bool> clearUserHistory(String? userId);

  /// Persist [history] to local storage.
  Future<void> saveHistory(List<ScanEntity> history, String? userId);
  
  /// Maximum number of scans to keep in history
  static const int maxHistoryItems = 50;
}