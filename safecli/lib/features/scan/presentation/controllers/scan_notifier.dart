// lib/features/scan/presentation/controllers/scan_notifier.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:safeclik/features/scan/data/models/scan_result.dart';
import 'package:safeclik/features/scan/domain/entities/scan_entity.dart';
import 'package:safeclik/features/scan/domain/repositories/scan_repository.dart';
import 'package:safeclik/features/scan/domain/usecases/clear_history_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/delete_scan_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/get_scan_history_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/save_history_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/scan_link_usecase.dart';
import 'package:safeclik/core/di/di.dart';
import 'package:safeclik/features/scan/data/repositories/scan_repository_impl.dart';
import 'scan_state.dart';

final scanNotifierProvider = StateNotifierProvider<ScanNotifier, ScanState>(
  (ref) => ScanNotifier(
    scanLinkUseCase: sl<ScanLinkUseCase>(),
    getHistoryUseCase: sl<GetScanHistoryUseCase>(),
    deleteUseCase: sl<DeleteScanUseCase>(),
    clearUseCase: sl<ClearHistoryUseCase>(),
    saveHistoryUseCase: sl<SaveHistoryUseCase>(),
    repo: sl<ScanRepositoryImpl>(),
  ),
);

class ScanNotifier extends StateNotifier<ScanState> {
  final ScanLinkUseCase _scanLinkUseCase;
  final GetScanHistoryUseCase _getHistoryUseCase;
  final DeleteScanUseCase _deleteUseCase;
  final ClearHistoryUseCase _clearUseCase;
  final SaveHistoryUseCase _saveHistoryUseCase;
  final ScanRepositoryImpl _repo;

  ScanNotifier({
    required ScanLinkUseCase scanLinkUseCase,
    required GetScanHistoryUseCase getHistoryUseCase,
    required DeleteScanUseCase deleteUseCase,
    required ClearHistoryUseCase clearUseCase,
    required SaveHistoryUseCase saveHistoryUseCase,
    required ScanRepositoryImpl repo,
  })  : _scanLinkUseCase = scanLinkUseCase,
        _getHistoryUseCase = getHistoryUseCase,
        _deleteUseCase = deleteUseCase,
        _clearUseCase = clearUseCase,
        _saveHistoryUseCase = saveHistoryUseCase,
        _repo = repo,
        super(const ScanState()) {
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
        source: e.source,
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
        source: r.source,
      );

  int _countDangerous(List<ScanResult> history) =>
      history.where((s) => s.safe == false).length;

  Future<void> _loadHistory() async {
    try {
      final entities = await _getHistoryUseCase();
      final results = entities.map(_toResult).toList();
      state = state.copyWith(
        scanHistory: results,
        dangerousScans: _countDangerous(results),
      );
      debugPrint('📂 [Load] Loaded ${results.length} records from local storage');
    } catch (e) {
      debugPrint('⚠️ [Load] Error loading history: $e');
    }
    _syncHistoryFromServer();
  }

  Future<void> _syncHistoryFromServer() async {
    try {
      final entities = await _repo.syncHistoryFromRemote();
      if (!mounted) return;
      final results = entities.map(_toResult).toList();
      
      if (results.length != state.scanHistory.length ||
          (results.isNotEmpty && 
           state.scanHistory.isNotEmpty && 
           results.first.id != state.scanHistory.first.id)) {
        state = state.copyWith(
          scanHistory: results,
          dangerousScans: _countDangerous(results),
        );
        debugPrint('🔄 [Sync] Updated from server: ${results.length} items');
      }
    } catch (e) {
      debugPrint('🔴 [Sync] Background sync error: $e');
    }
  }

  Future<void> refreshHistory() => _syncHistoryFromServer();

  Future<ScanResult?> scanLink(String link) async {
    if (state.isScanning) return null;

    try {
      state = state.copyWith(isScanning: true, lastError: null);

      final entity = await _scanLinkUseCase(link);

      if (entity == null) throw Exception('تعذر فحص الرابط');

      final result = _toResult(entity);
      
      var newHistory = [result, ...state.scanHistory];
      
      if (newHistory.length > ScanRepository.maxHistoryItems) {
        newHistory = newHistory.sublist(0, ScanRepository.maxHistoryItems);
        debugPrint('📊 [Limit] History trimmed to ${ScanRepository.maxHistoryItems} items');
      }

      await _saveHistoryUseCase(newHistory.map(_toEntity).toList());

      state = state.copyWith(
        scanHistory: newHistory,
        dangerousScans: _countDangerous(newHistory),
        isScanning: false,
      );

      debugPrint('✅ [Scan] Success: ${result.link} (Total: ${newHistory.length})');
      return result;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ [Scan] Error: $errorMessage');
      state = state.copyWith(lastError: errorMessage, isScanning: false);
      return null;
    }
  }

  Future<void> clearHistory() async {
    debugPrint('🗑️ [Clear] Starting clear history...');
    state = state.copyWith(isLoading: true);
    
    try {
      final success = await _clearUseCase();
      debugPrint('🗑️ [Clear] UseCase result: $success');
      
      if (success) {
        await _saveHistoryUseCase([]);
        
        state = state.copyWith(
          scanHistory: [],
          dangerousScans: 0,
          isLoading: false,
          lastError: null,
        );
        debugPrint('✅ [Clear] History cleared successfully');
      } else {
        // محاولة المسح المحلي
        await _saveHistoryUseCase([]);
        
        state = state.copyWith(
          scanHistory: [],
          dangerousScans: 0,
          isLoading: false,
        );
        debugPrint('✅ [Clear] Local clear successful');
      }
    } catch (e) {
      debugPrint('🔴 [Clear] Error: $e');
      
      try {
        await _saveHistoryUseCase([]);
        state = state.copyWith(
          scanHistory: [],
          dangerousScans: 0,
          isLoading: false,
        );
      } catch (localError) {
        state = state.copyWith(
          isLoading: false,
          lastError: 'فشل مسح السجل: $e',
        );
      }
    }
  }


Future<void> softDeleteScanResult(String id) async {
    debugPrint('🗑️ [SoftDelete] Starting for ID: $id');
    state = state.copyWith(isLoading: true);
    
    try {
      // Soft delete through repository
      final success = await _deleteUseCase(id); // This now does soft delete
      
      if (success) {
        // Remove from local state
        final newHistory = state.scanHistory.where((s) => s.id != id).toList();
        
        state = state.copyWith(
          scanHistory: newHistory,
          dangerousScans: _countDangerous(newHistory),
          isLoading: false,
        );
        
        debugPrint('✅ [SoftDelete] Successfully hid scan: $id');
      } else {
        state = state.copyWith(
          isLoading: false,
          lastError: 'فشل إخفاء الفحص',
        );
      }
    } catch (e) {
      debugPrint('🔴 [SoftDelete] Error: $e');
      state = state.copyWith(
        isLoading: false,
        lastError: 'حدث خطأ: $e',
      );
    }
  }

  Future<void> clearUserHistory() async {
    debugPrint('🗑️ [SoftDelete] Clearing all user history...');
    state = state.copyWith(isLoading: true);
    
    try {
      final success = await _clearUseCase(); // This now does soft delete for all
      
      if (success) {
        state = state.copyWith(
          scanHistory: [],
          dangerousScans: 0,
          isLoading: false,
          lastError: null,
        );
        debugPrint('✅ [SoftDelete] All scans hidden from user');
      } else {
        state = state.copyWith(
          isLoading: false,
          lastError: 'فشل إخفاء السجل',
        );
      }
    } catch (e) {
      debugPrint('🔴 [SoftDelete] Error: $e');
      state = state.copyWith(
        isLoading: false,
        lastError: 'حدث خطأ: $e',
      );
    }
  }
  
  void clearError() => state = state.copyWith(lastError: null);

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
}

// ── Search & Filter Providers ──
final historyFilterProvider = StateProvider<int>((ref) => 0); // 0: All, 1: Safe, 2: Suspicious, 3: Dangerous
final historySearchProvider = StateProvider<String>((ref) => '');

final filteredHistoryProvider = Provider<List<ScanResult>>((ref) {
  final history = ref.watch(scanNotifierProvider).scanHistory;
  final filter = ref.watch(historyFilterProvider);
  final search = ref.watch(historySearchProvider).toLowerCase();

  List<ScanResult> tabFiltered;
  switch (filter) {
    case 1:
      tabFiltered = history.where((s) => s.safe == true).toList();
      break;
    case 2:
      tabFiltered = history.where((s) => s.safe == null).toList();
      break;
    case 3:
      tabFiltered = history.where((s) => s.safe == false).toList();
      break;
    default:
      tabFiltered = history;
  }

  if (search.isNotEmpty) {
    return tabFiltered.where((scan) {
      return scan.link.toLowerCase().contains(search) ||
          scan.message.toLowerCase().contains(search) ||
          scan.details.any((d) => d.toLowerCase().contains(search));
    }).toList();
  }
  
  return tabFiltered;
});