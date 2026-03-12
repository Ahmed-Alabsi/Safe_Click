// lib/features/scan/data/repositories/scan_repository_impl.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:safeclik/core/utils/scan_cache_service.dart';
import 'package:safeclik/features/scan/data/models/scan_result.dart';
import 'package:safeclik/features/scan/data/datasources/remote_scan_datasource.dart';
import '../../domain/entities/scan_entity.dart';
import '../../domain/repositories/scan_repository.dart';

class ScanRepositoryImpl implements ScanRepository {
  final RemoteScanDataSource _remote;
  final ScanCacheService _cache;

  ScanRepositoryImpl({
    required RemoteScanDataSource remote,
    required ScanCacheService cache,
  })  : _remote = remote,
        _cache = cache;

  ScanEntity _toEntity(ScanResult model) => model.toEntity();

  ScanResult _toModel(ScanEntity entity) => ScanResult(
        id: entity.id,
        link: entity.link,
        safe: entity.safe,
        score: entity.score,
        message: entity.message,
        details: entity.details,
        timestamp: entity.timestamp,
        rawData: entity.rawData,
        responseTime: entity.responseTime,
        ipAddress: entity.ipAddress,
        domain: entity.domain,
        threatsCount: entity.threatsCount,
        source: entity.source,
      );

  // يحافظ على آخر 50 عنصر فقط (FIFO)
  List<T> _limitHistory<T>(List<T> history) {
    if (history.length <= ScanRepository.maxHistoryItems) {
      return history;
    }
    return history.sublist(0, ScanRepository.maxHistoryItems);
  }

  @override
  Future<ScanEntity?> scanLink(String link) async {
    link = link.trim();
    if (link.isEmpty) throw Exception('الرجاء إدخال رابط للفحص');

    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }

    try {
      final uri = Uri.parse(link);
      final host = uri.host;
      if (host.isEmpty || !host.contains('.')) {
        throw Exception('الرجاء إدخال رابط صالح');
      }
    } catch (e) {
      throw Exception('الرجاء إدخال رابط صالح');
    }

    // ── 1. Check local url_cache first ──────────────────────────────────────
    final cached = await _cache.getCachedResult(link);
    if (cached != null) {
      debugPrint('✅ [Cache] HIT — returning local result for $link');

      // Decode the full engine_results JSON that was stored verbatim from the
      // backend response. We then reconstruct a ScanResult via fromJson so that
      // every field (score, details, domain, threatsCount, rawData …) is
      // identical to what the user would see with a fresh server call.
      final engineData = (cached.engineResults.isNotEmpty)
          ? Map<String, dynamic>.from(
              jsonDecode(cached.engineResults) as Map<String, dynamic>,
            )
          : <String, dynamic>{};

      // Patch fields that the cached JSON might not have stored, so fromJson
      // always gets a complete object.
      engineData.putIfAbsent('id',
          () => 'cache_${cached.urlHash.substring(0, 8)}');
      engineData.putIfAbsent('link', () => cached.url);
      engineData.putIfAbsent(
          'timestamp',
          () => DateTime.fromMillisecondsSinceEpoch(cached.createdAt * 1000)
              .toIso8601String());
      engineData.putIfAbsent('source', () => 'local_cache');

      // Re-use ScanResult.fromJson so all fields are parsed identically to
      // a live response — no hand-crafted fallbacks needed.
      final result = ScanResult.fromJson(engineData);
      return _toEntity(result);
    }

    // ── 2. Cache MISS → call backend ─────────────────────────────────────────
    debugPrint('🌐 [API] Calling SafeClick backend for $link');
    try {
      final response = await _remote.scanLink(link);

      if (response['success'] == true && response['result'] != null) {
        final resultData = response['result'];
        final scanResult = ScanResult.fromJson(resultData);
        final entity     = _toEntity(scanResult);

        // ── 3. Store result in url_cache ─────────────────────────────────────
        final classification = entity.safe == true
            ? 'safe'
            : entity.safe == false
                ? 'malicious'
                : 'suspicious';

        final cacheEntry = UrlCacheEntry.create(
          url:            link,
          classification: classification,
          engineResults:  resultData,
        );
        await _cache.setCachedResult(cacheEntry);

        return entity;
      } else {
        final message = response['message']?.toString() ?? 'فشل الفحص';
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('🔴 [API] Backend error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ScanEntity>> getScanHistory(String? userId) async {
    try {
      // 1. Load local history from SQLite for specific user
      final localHistoryData = await _cache.getScansHistory(userId);
      debugPrint('📦 [History] Read from SQLite for user $userId: ${localHistoryData.length} records');
      
      // 2. Apply limit
      final limitedHistoryData = _limitHistory(localHistoryData);
      
      return limitedHistoryData.map((data) => _toEntity(ScanResult.fromJson(data))).toList();
    } catch (e) {
      debugPrint('📦 [History] Local read error: $e');
      return [];
    }
  }

  @override
  Future<List<ScanEntity>> syncHistoryFromRemote(String? userId) async {
    try {
      final response = await _remote.getScanHistory();
      if (response['success'] == true) {
        final List<dynamic> historyData = response['history'] ?? [];
        
        // Convert to models first
        final entities = historyData
            .map((data) => _toEntity(ScanResult.fromJson(data)))
            .toList();
        
        // Clear local history for this user only
        await _cache.clearUserHistory(userId);
        
        // Convert to models for storage
        final models = entities.map(_toModel).toList();
        final modelsData = models.map((m) => m.toJson()).toList().cast<Map<String, dynamic>>();

        // Save to SQLite
        await _cache.saveScansHistory(modelsData, userId);
        debugPrint('🔄 [History] Synced ${modelsData.length} records from server for user $userId');
        
        // Return latest from local DB
        return getScanHistory(userId);
      } else {
        throw Exception(response['message'] ?? 'فشل مزامنة السجل');
      }
    } catch (e) {
      debugPrint('🔴 [History] Remote sync failed: $e');
      rethrow; // Important: rethrow so Notifier knows it failed
    }
  }

  Future<bool> softDeleteScan(String id) async {
    try {
      await _cache.softDeleteScan(id);
      
      // Sync with server
      final response = await _remote.deleteScan(id);
      debugPrint('✅ [SoftDelete] Scan hidden from user (Remote: ${response['success']}): $id');
      
      return true;
    } catch (e) {
      debugPrint('🔴 [SoftDelete] Failed: $e');
      return false;
    }
  }

  @override
  Future<bool> clearUserHistory(String? userId) async {
    try {
      await _cache.clearUserHistory(userId);
      
      // Sync with server
      final response = await _remote.clearHistory();
      debugPrint('✅ [SoftDelete] All scans hidden for user $userId (Remote: ${response['success']})');
      
      return true;
    } catch (e) {
      debugPrint('🔴 [SoftDelete] Clear failed: $e');
      return false;
    }
  }

  @override
  Future<void> saveHistory(List<ScanEntity> history, String? userId) async {
    try {
      final models = history.map(_toModel).toList();
      final modelsData = models.map((m) => m.toJson()).toList().cast<Map<String, dynamic>>();
      
      await _cache.saveScansHistory(modelsData, userId);
      debugPrint('💾 [Save] Saved ${modelsData.length} records for user $userId');
    } catch (e) {
      debugPrint('🔴 [Save] Failed to save history: $e');
      rethrow;
    }
  }
}