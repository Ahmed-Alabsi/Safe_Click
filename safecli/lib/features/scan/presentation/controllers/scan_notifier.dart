// lib/features/scan/presentation/controllers/scan_notifier.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_controller.dart';
import 'package:safeclik/features/settings/presentation/providers/settings_controller.dart';

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
import 'package:safeclik/core/network/scan_api.dart';
import 'scan_state.dart';

final scanNotifierProvider = StateNotifierProvider<ScanNotifier, ScanState>(
  (ref) {
    final notifier = ScanNotifier(
      ref: ref,
      scanLinkUseCase: sl<ScanLinkUseCase>(),
      getHistoryUseCase: sl<GetScanHistoryUseCase>(),
      deleteUseCase: sl<DeleteScanUseCase>(),
      clearUseCase: sl<ClearHistoryUseCase>(),
      saveHistoryUseCase: sl<SaveHistoryUseCase>(),
      repo: sl<ScanRepositoryImpl>(),
    );

    // Watch for auth state changes to sync/reset
    ref.listen(authProvider.select((a) => a.user?.id), (previous, next) {
      if (next != null) {
        debugPrint('👤 [Session] User logged in: $next. Syncing scan history...');
        notifier.refreshHistory();
      } else if (previous != null && next == null) {
        debugPrint('👤 [Session] User logged out. Resetting scan state...');
        notifier.reset();
      }
    });

    return notifier;
  },
);

class ScanNotifier extends StateNotifier<ScanState> {
  final ScanLinkUseCase _scanLinkUseCase;
  final GetScanHistoryUseCase _getHistoryUseCase;
  final DeleteScanUseCase _deleteUseCase;
  final ClearHistoryUseCase _clearUseCase;
  final SaveHistoryUseCase _saveHistoryUseCase;
  final ScanRepositoryImpl _repo;
  final Ref _ref;

  ScanNotifier({
    required Ref ref,
    required ScanLinkUseCase scanLinkUseCase,
    required GetScanHistoryUseCase getHistoryUseCase,
    required DeleteScanUseCase deleteUseCase,
    required ClearHistoryUseCase clearUseCase,
    required SaveHistoryUseCase saveHistoryUseCase,
    required ScanRepositoryImpl repo,
  })  : _ref = ref,
        _scanLinkUseCase = scanLinkUseCase,
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
    final userId = _ref.read(authProvider).user?.id;
    try {
      final entities = await _getHistoryUseCase(userId);
      final results = entities.map(_toResult).toList();
      state = state.copyWith(
        scanHistory: results,
        dangerousScans: _countDangerous(results),
      );
      debugPrint('📂 [Load] Loaded ${results.length} records from local storage for user $userId');
    } catch (e) {
      debugPrint('⚠️ [Load] Error loading history: $e');
    }
    _syncHistoryFromServer();
  }

  Future<void> _syncHistoryFromServer() async {
    final userId = _ref.read(authProvider).user?.id;
    if (userId == null) return;
    
    try {
      final entities = await _repo.syncHistoryFromRemote(userId);
      if (!mounted) return;
      final results = entities.map(_toResult).toList();
      
      // Update state with server data
      state = state.copyWith(
        scanHistory: results,
        dangerousScans: _countDangerous(results),
      );
      debugPrint('🔄 [Sync] Updated from server: ${results.length} items');
      
    } catch (e) {
      debugPrint('🔴 [Sync] Background sync failed: $e. Keeping local data.');
      // Keep existing state if sync fails
    }
  }

  Future<void> refreshHistory() => _syncHistoryFromServer();

  Future<ScanResult?> scanLink(String link) async {
  if (state.isScanning) return null;

  final authState = _ref.read(authProvider);
  final isGuest = authState.isGuest;
  final settingsState = _ref.read(settingsProvider);
  final scanLevel = settingsState.value?.scanLevel ?? 'deep';

  try {
    state = state.copyWith(isScanning: true, lastError: null);

    final entity = await _scanLinkUseCase(link, scanLevel: scanLevel);

    if (entity == null) throw Exception('تعذر فحص الرابط');

    final result = _toResult(entity);
    
    // ✅ للمستخدمين المسجلين: احفظ في التاريخ مع قاعدة البيانات
    if (!isGuest) {
      var newHistory = [result, ...state.scanHistory];
      
      if (newHistory.length > ScanRepository.maxHistoryItems) {
        newHistory = newHistory.sublist(0, ScanRepository.maxHistoryItems);
        debugPrint('📊 [Limit] History trimmed to ${ScanRepository.maxHistoryItems} items');
      }

      final userId = _ref.read(authProvider).user?.id;
      await _saveHistoryUseCase(newHistory.map(_toEntity).toList(), userId);

      state = state.copyWith(
        scanHistory: newHistory,
        dangerousScans: _countDangerous(newHistory),
        isScanning: false,
      );
    } else {
      // ✅ للزوار: أضف النتيجة محلياً فقط بدون حفظ في قاعدة البيانات
      var newHistory = [result, ...state.scanHistory];
      
      if (newHistory.length > ScanRepository.maxHistoryItems) {
        newHistory = newHistory.sublist(0, ScanRepository.maxHistoryItems);
      }

      state = state.copyWith(
        scanHistory: newHistory,
        dangerousScans: _countDangerous(newHistory),
        isScanning: false,
      );
    }

    debugPrint('✅ [Scan] Success: ${result.link} (User: ${isGuest ? 'Guest' : 'Registered'})');
    return result;
  } catch (e) {
    final errorMessage = e.toString().replaceFirst('Exception: ', '');
    debugPrint('❌ [Scan] Error: $errorMessage');
    state = state.copyWith(lastError: errorMessage, isScanning: false);
    return null;
  }
}

  Future<void> clearHistory() async {
    final userId = _ref.read(authProvider).user?.id;
    debugPrint('🗑️ [Clear] Starting clear history for user $userId...');
    state = state.copyWith(isLoading: true);
    
    try {
      final success = await _clearUseCase(userId);
      debugPrint('🗑️ [Clear] UseCase result: $success');
      
      if (success) {
        await _saveHistoryUseCase([], userId);
        
        state = state.copyWith(
          scanHistory: [],
          dangerousScans: 0,
          isLoading: false,
          lastError: null,
        );
        debugPrint('✅ [Clear] History cleared successfully');
      } else {
        // محاولة المسح المحلي
        await _saveHistoryUseCase([], userId);
        
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
        await _saveHistoryUseCase([], userId);
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


  void removeScanLocally(String id) {
    final newHistory = state.scanHistory.where((s) => s.id != id).toList();
    state = state.copyWith(
      scanHistory: newHistory,
      dangerousScans: _countDangerous(newHistory),
    );
  }

  void clearHistoryLocally() {
    state = state.copyWith(
      scanHistory: [],
      dangerousScans: 0,
    );
  }

  Future<void> softDeleteScanResult(String id) async {
    debugPrint('🗑️ [SoftDelete] Executing delayed backend delete for ID: $id');
    try {
      final success = await _deleteUseCase(id);
      if (success) {
        debugPrint('✅ [SoftDelete] Successfully deleted scan on backend: $id');
      }
    } catch (e) {
      debugPrint('🔴 [SoftDelete] Error: $e');
    }
  }

  Future<bool> restoreScanResult(String id) async {
    debugPrint('🔄 [Restore] Executing background restore for ID: $id');
    try {
      final success = await sl<ScanApi>().restoreScan(id);
      if (success['success'] == true) {
        debugPrint('✅ [Restore] Successfully restored scan on backend: $id');
        return true;
      }
    } catch (e) {
      debugPrint('🔴 [Restore] Error: $e');
    }
    return false;
  }

  Future<bool> restoreScansBulk(List<String> ids) async {
    if (ids.isEmpty) return true;
    debugPrint('🔄 [RestoreBulk] Executing background restore for ${ids.length} scans...');
    try {
      final success = await sl<ScanApi>().restoreScansBulk(ids);
      if (success['success'] == true) {
        debugPrint('✅ [RestoreBulk] Successfully restored scans on backend');
        return true;
      }
    } catch (e) {
      debugPrint('🔴 [RestoreBulk] Error: $e');
    }
    return false;
  }


  Future<void> clearUserHistory() async {
    final userId = _ref.read(authProvider).user?.id;
    debugPrint('🗑️ [SoftDelete] Executing background clear all history for user $userId...');
    
    try {
      final success = await _clearUseCase(userId); 
      if (success) {
        debugPrint('✅ [SoftDelete] All scans hidden from user on backend');
      }
    } catch (e) {
      debugPrint('🔴 [SoftDelete] Error: $e');
    }
  }
  
  void clearError() => state = state.copyWith(lastError: null);
void addScanResult(ScanResult result) {
  if (!state.scanHistory.any((scan) => scan.id == result.id)) {
    final newHistory = [result, ...state.scanHistory]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = state.copyWith(
      scanHistory: newHistory,
      dangerousScans: _countDangerous(newHistory),
    );
  }
}

void addScansLocally(List<ScanResult> scans) {
  final currentList = state.scanHistory;
  final newIds = scans.map((s) => s.id).toSet();
  final filteredList = currentList.where((s) => !newIds.contains(s.id)).toList();
  final newHistory = [...scans, ...filteredList]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  state = state.copyWith(
    scanHistory: newHistory,
    dangerousScans: _countDangerous(newHistory),
  );
}
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