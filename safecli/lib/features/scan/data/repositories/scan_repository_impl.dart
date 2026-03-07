// lib/features/scan/data/repositories/scan_repository_impl.dart
//
// PHASE 1: Flutter no longer calls VirusTotal or any external threat API.
// ALL scanning is delegated exclusively to the Django backend.
//
// PHASE 2: SQLite local cache (ScanCacheService) is checked BEFORE network.
// Cache TTL = 24 hours. Key = SHA-256(normalized URL).

import 'package:flutter/foundation.dart';

import 'package:safeclik/core/utils/scan_cache_service.dart';
import 'package:safeclik/core/utils/local_storage_service.dart';
import 'package:safeclik/features/scan/data/models/scan_result.dart';
import 'package:safeclik/features/scan/data/datasources/remote_scan_datasource.dart';
import '../../domain/entities/scan_entity.dart';
import '../../domain/repositories/scan_repository.dart';

class ScanRepositoryImpl implements ScanRepository {
  final RemoteScanDataSource _remote;
  final ScanCacheService _cache;
  final LocalStorageService _localStorage;

  ScanRepositoryImpl({
    required RemoteScanDataSource remote,
    required ScanCacheService cache,
    required LocalStorageService localStorage,
  })  : _remote = remote,
        _cache = cache,
        _localStorage = localStorage;

  // ── Mappers ───────────────────────────────────────────────────────────────

  ScanEntity _toEntity(ScanResult r) => ScanEntity(
        id: r.id,
        link: r.link,
        safe: r.safe,
        score: r.score,
        message: r.message,
        details: r.details,
        timestamp: r.timestamp,
        rawData: r.rawData,
        responseTime: r.responseTime,
        ipAddress: r.ipAddress,
        domain: r.domain,
        threatsCount: r.threatsCount,
      );

  ScanResult _toModel(ScanEntity e) => ScanResult(
        id: e.id,
        link: e.link,
        safe: e.safe,
        score: e.score,
        message: e.message,
        details: e.details,
        timestamp: e.timestamp,
        rawData: e.rawData,
        responseTime: e.responseTime,
        ipAddress: e.ipAddress,
        domain: e.domain,
        threatsCount: e.threatsCount,
      );

  // ── ScanRepository ────────────────────────────────────────────────────────

  @override
  Future<ScanEntity?> scanLink(String link) async {
    // ── Step 1: Normalize ──────────────────────────────────────────────────
    link = link.trim();
    if (link.isEmpty) throw Exception('الرجاء إدخال رابط للفحص');

    // Add scheme if missing
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }

    // Phase 2 Fix: Basic URL validation — reject obvious non-URLs
    try {
      final uri = Uri.parse(link);
      final host = uri.host;
      if (host.isEmpty || !host.contains('.')) {
        throw Exception('الرجاء إدخال رابط صالح (مثال: example.com بنطاق صحيح)');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('الرجاء')) {
        rethrow;
      }
      throw Exception('الرجاء إدخال رابط صالح');
    }

    // final cached = await _cache.getCache(link);
    // if (cached != null) {
    //   debugPrint('🟢 [Cache] Local SQLite cache hit for $link');
    //   // Reconstruct a minimal ScanResult from cache entry
    //   final cachedResult = ScanResult(
    //     id: 'cache_${cached.urlHash}',
    //     link: cached.url,
    //     safe: cached.result == 'safe'
    //         ? true
    //         : cached.result == 'malicious'
    //             ? false
    //             : null,
    //     score: cached.riskScore,
    //     message: _messageFromResult(cached.result),
    //     details: ['✅ من الكاش المحلي — فحص مسبق', 'النتيجة: ${cached.result}'],
    //     timestamp: cached.scannedAt,
    //     source: 'Local Cache',
    //   );
    //   return _toEntity(cachedResult);
    // }

    // ── Step 3: Call Django backend exclusively ────────────────────────────
    debugPrint('🌐 [API] Calling SafeClick backend for $link');
    try {
      final response = await _remote.scanLink(link);

      if (response['success'] == true && response['result'] != null) {
        final resultData = response['result'];
        final scanResult = ScanResult.fromJson(resultData);

        // ── Step 4: Store in local cache ─────────────────────────────────
        // await _cache.putCache(ScanCacheEntry(
        //   urlHash: computeUrlHash(link),
        //   url: link,
        //   result: scanResult.safe == true
        //       ? 'safe'
        //       : scanResult.safe == false
        //           ? 'malicious'
        //           : 'suspicious',
        //   threatLevel: _threatLevel(scanResult.score),
        //   riskScore: scanResult.score,
        //   scannedAt: DateTime.now(),
        // ));

        return _toEntity(scanResult);
      } else {
        // Server returned success=false
        final message = response['message']?.toString() ?? 'فشل الفحص';
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('🔴 [API] Backend error: $e');
      rethrow;
    }
  }

  // ── History ───────────────────────────────────────────────────────────────

  @override
  Future<List<ScanEntity>> getScanHistory() async {
    // LOCAL-FIRST: Return local data immediately for instant UI.
    // Background sync happens via syncHistoryFromRemote().
    try {
      final localHistory = await _localStorage.getScanHistory();
      if (localHistory.isNotEmpty) {
        debugPrint('📦 [History] Returning ${localHistory.length} local records instantly');
        return localHistory.map(_toEntity).toList();
      }
    } catch (e) {
      debugPrint('📦 [History] Local read error: $e');
    }

    // No local data yet — try remote once on first load
    return syncHistoryFromRemote();
  }

  /// Fetch history from the server and persist locally.
  /// Call this in the background after showing local data.
  Future<List<ScanEntity>> syncHistoryFromRemote() async {
    try {
      final response = await _remote.getScanHistory();
      if (response['success'] == true) {
        final List<dynamic> historyData = response['history'] ?? [];
        final entities = historyData
            .map((data) => _toEntity(ScanResult.fromJson(data)))
            .toList();
        // Persist locally so next load is instant
        await _localStorage.saveScanHistory(entities.map(_toModel).toList());
        debugPrint('🔄 [History] Synced ${entities.length} records from server');
        return entities;
      }
    } catch (e) {
      debugPrint('🔴 [History] Remote sync failed: $e');
    }
    return [];
  }

  @override
  Future<bool> deleteScan(String id) async {
    try {
      final response = await _remote.deleteScan(id);
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> clearHistory() async {
    try {
      final response = await _remote.clearHistory();
      if (response['success'] == true) {
        await _localStorage.saveScanHistory([]);
        await _cache.clearAll();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveHistory(List<ScanEntity> history) async {
    final models = history.map(_toModel).toList();
    await _localStorage.saveScanHistory(models);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _messageFromResult(String result) {
    switch (result) {
      case 'safe':
        return '✅ الرابط آمن';
      case 'malicious':
        return '🔴 الرابط خطير!';
      default:
        return '⚠️ الرابط مشبوه';
    }
  }

  String _threatLevel(int score) {
    if (score >= 70) return 'none';
    if (score >= 40) return 'medium';
    return 'high';
  }
}
