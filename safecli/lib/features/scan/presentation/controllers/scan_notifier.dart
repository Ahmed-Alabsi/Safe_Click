import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:safeclik/features/scan/data/models/scan_result.dart';
import 'package:safeclik/features/scan/domain/entities/scan_entity.dart';
import 'package:safeclik/features/scan/domain/usecases/clear_history_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/delete_scan_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/get_scan_history_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/save_history_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/scan_link_usecase.dart';
import 'package:safeclik/core/di/di.dart';
import 'package:safeclik/core/utils/scan_cache_service.dart';
import 'package:safeclik/features/scan/data/repositories/scan_repository_impl.dart';
import 'scan_state.dart';

final scanNotifierProvider = StateNotifierProvider<ScanNotifier, ScanState>(
  (ref) => ScanNotifier(),
);

class ScanNotifier extends StateNotifier<ScanState> {
  final ScanLinkUseCase _scanLinkUseCase = sl<ScanLinkUseCase>();
  final GetScanHistoryUseCase _getHistoryUseCase = sl<GetScanHistoryUseCase>();
  final DeleteScanUseCase _deleteUseCase = sl<DeleteScanUseCase>();
  final ClearHistoryUseCase _clearUseCase = sl<ClearHistoryUseCase>();
  final SaveHistoryUseCase _saveHistoryUseCase = sl<SaveHistoryUseCase>();
  final ScanCacheService _scanCache = sl<ScanCacheService>();

  ScanNotifier() : super(const ScanState()) {
    // Phase 3: Purge expired cache entries at startup
    _scanCache.purgeExpired();
    _loadHistory();
  }

  ScanResult _toResult(ScanEntity e) => ScanResult(
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

  int _countDangerous(List<ScanResult> history) =>
      history.where((s) => s.safe == false).length;

  // LOCAL-FIRST: show local data immediately, then sync from server in background
  Future<void> _loadHistory() async {
    try {
      // Step 1: Instant local data
      final entities = await _getHistoryUseCase();
      final results = entities.map(_toResult).toList();
      state = state.copyWith(
        scanHistory: results,
        dangerousScans: _countDangerous(results),
      );
    } catch (e) {
      debugPrint('خطأ في تحميل السجل المحلي: $e');
    }
    // Step 2: Background sync with server (does NOT block UI)
    _syncHistoryFromServer();
  }

  /// Silently sync history from server and update state if new data arrives.
  Future<void> _syncHistoryFromServer() async {
    try {
      final repo = sl<ScanRepositoryImpl>();
      final entities = await repo.syncHistoryFromRemote();
      if (!mounted) return;
      final results = entities.map(_toResult).toList();
      // Only update if server returned different data
      if (results.length != state.scanHistory.length ||
          (results.isNotEmpty &&
              state.scanHistory.isNotEmpty &&
              results.first.id != state.scanHistory.first.id)) {
        state = state.copyWith(
          scanHistory: results,
          dangerousScans: _countDangerous(results),
        );
        debugPrint('🔄 [ScanNotifier] History updated from server: ${results.length} items');
      }
    } catch (e) {
      debugPrint('🔴 [ScanNotifier] Background sync error: $e');
    }
  }

  /// Public: call on pull-to-refresh.
  Future<void> refreshHistory() => _syncHistoryFromServer();

  Future<ScanResult?> scanLink(String link) async {
    // Phase B: Scan concurrent block
    if (state.isScanning) return null;

    try {
      state = state.copyWith(isScanning: true, clearError: true);

      final entity = await _scanLinkUseCase(link);

      if (entity == null) throw Exception('تعذر فحص الرابط');

      final result = _toResult(entity);
      final newHistory = [result, ...state.scanHistory];

      await _saveHistoryUseCase(newHistory.map(_toEntity).toList());

      state = state.copyWith(
        scanHistory: newHistory,
        dangerousScans: _countDangerous(newHistory),
        isScanning: false,
      );

      debugPrint('✅ تم حفظ نتيجة الفحص');
      return result;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ خطأ في الفحص: $errorMessage');
      state = state.copyWith(lastError: errorMessage, isScanning: false);
      return null;
    }
  }

  Future<void> clearHistory() async {
    try {
      final success = await _clearUseCase();
      if (success) {
        state = state.copyWith(
          scanHistory: [],
          dangerousScans: 0,
          clearError: true,
        );
      } else {
        state = state.copyWith(lastError: 'فشل مسح السجل من الخادم');
      }
    } catch (_) {
      state = state.copyWith(lastError: 'خطأ في مسح السجل');
    }
  }

  Future<void> deleteScanResult(String id) async {
    try {
      final success = await _deleteUseCase(id);
      if (success) {
        final newHistory =
            state.scanHistory.where((s) => s.id != id).toList();
        await _saveHistoryUseCase(newHistory.map(_toEntity).toList());
        state = state.copyWith(
          scanHistory: newHistory,
          dangerousScans: _countDangerous(newHistory),
        );
      } else {
        state = state.copyWith(lastError: 'فشل حذف الفحص');
      }
    } catch (_) {
      state = state.copyWith(lastError: 'خطأ في حذف الفحص');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  void reset() {
    state = const ScanState();
  }

  ScanResult? getScanById(String id) {
    try {
      return state.scanHistory.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, int> getStats() {
    final h = state.scanHistory;
    return {
      'total': h.length,
      'safe': h.where((s) => s.safe == true).length,
      'dangerous': h.where((s) => s.safe == false).length,
      'suspicious': h.where((s) => s.safe == null).length,
    };
  }

  Map<String, dynamic> getAdvancedStats() {
    final h = state.scanHistory;
    final total = h.length;
    if (total == 0) {
      return {
        'total': 0, 'safe': 0, 'dangerous': 0, 'suspicious': 0,
        'safePercentage': 0, 'dangerousPercentage': 0, 'suspiciousPercentage': 0,
        'averageScore': 0, 'mostScannedDay': null, 'maxScansInDay': 0,
      };
    }

    // Phase 3: Single-pass fold — O(n) instead of O(4n)
    final Map<String, int> byDay = {};
    final result = h.fold(
      <String, dynamic>{'safe': 0, 'dangerous': 0, 'suspicious': 0, 'scoreSum': 0},
      (acc, s) {
        if (s.safe == true) { acc['safe'] = (acc['safe'] as int) + 1; }
        else if (s.safe == false) { acc['dangerous'] = (acc['dangerous'] as int) + 1; }
        else { acc['suspicious'] = (acc['suspicious'] as int) + 1; }
        acc['scoreSum'] = (acc['scoreSum'] as int) + s.score;
        final key = '${s.timestamp.year}-${s.timestamp.month}-${s.timestamp.day}';
        byDay[key] = (byDay[key] ?? 0) + 1;
        return acc;
      },
    );

    final safe = result['safe'] as int;
    final dangerous = result['dangerous'] as int;
    final suspicious = result['suspicious'] as int;
    final avgScore = (result['scoreSum'] as int) / total;

    String? mostScannedDay;
    int maxScans = 0;
    byDay.forEach((day, count) {
      if (count > maxScans) { maxScans = count; mostScannedDay = day; }
    });

    return {
      'total': total,
      'safe': safe, 'dangerous': dangerous, 'suspicious': suspicious,
      'safePercentage': (safe / total * 100).roundToDouble(),
      'dangerousPercentage': (dangerous / total * 100).roundToDouble(),
      'suspiciousPercentage': (suspicious / total * 100).roundToDouble(),
      'averageScore': avgScore.roundToDouble(),
      'mostScannedDay': mostScannedDay,
      'maxScansInDay': maxScans,
    };
  }

  String exportHistoryAsJson() {
    try {
      final exportData = state.scanHistory
          .map((scan) => {
                'id': scan.id,
                'link': scan.link,
                'safe': scan.safe,
                'score': scan.score,
                'message': scan.message,
                'details': scan.details,
                'timestamp': scan.timestamp.toIso8601String(),
                'threatsCount': scan.threatsCount,
              })
          .toList();
      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('خطأ في تصدير السجل: $e');
      return '[]';
    }
  }

  List<ScanResult> searchInHistory(String query) {
    if (query.isEmpty) return [];
    final lower = query.toLowerCase();
    return state.scanHistory.where((scan) {
      return scan.link.toLowerCase().contains(lower) ||
          scan.message.toLowerCase().contains(lower) ||
          scan.details.any((d) => d.toLowerCase().contains(lower));
    }).toList();
  }

  // Phase 4: enableVirusTotal() removed — VirusTotal is no longer used from Flutter.
}
