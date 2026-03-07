// lib/features/scan/domain/repositories/scan_repository.dart

import '../entities/scan_entity.dart';

abstract class ScanRepository {
  /// Scan a URL. Returns a [ScanEntity] or null on unrecoverable failure.
  Future<ScanEntity?> scanLink(String link);

  /// Fetch scan history — LOCAL FIRST (returns local data instantly).
  Future<List<ScanEntity>> getScanHistory();

  /// Sync history from remote server and persist locally.
  /// Call this in the background after [getScanHistory] returns local data.
  Future<List<ScanEntity>> syncHistoryFromRemote();

  /// Delete a single scan record by id. Returns true on success.
  Future<bool> deleteScan(String id);

  /// Clear the entire scan history (remote + local). Returns true on success.
  Future<bool> clearHistory();

  /// Persist [history] to local storage.
  Future<void> saveHistory(List<ScanEntity> history);
}

