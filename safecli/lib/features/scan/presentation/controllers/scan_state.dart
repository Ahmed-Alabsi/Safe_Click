// lib/features/scan/presentation/controllers/scan_state.dart
//
// Immutable state class consumed by ScanNotifier.
// Uses ScanResult (the existing model) so that view files that
// already accept ScanResult as a type continue to compile unchanged.

import 'package:safeclik/features/scan/data/models/scan_result.dart';

class ScanState {
  final List<ScanResult> scanHistory;
  final bool isScanning;
  final String? lastError;
  final int dangerousScans;

  const ScanState({
    this.scanHistory = const [],
    this.isScanning = false,
    this.lastError,
    this.dangerousScans = 0,
  });

  ScanState copyWith({
    List<ScanResult>? scanHistory,
    bool? isScanning,
    String? lastError,
    int? dangerousScans,
    bool clearError = false,
  }) {
    return ScanState(
      scanHistory: scanHistory ?? this.scanHistory,
      isScanning: isScanning ?? this.isScanning,
      lastError: clearError ? null : (lastError ?? this.lastError),
      dangerousScans: dangerousScans ?? this.dangerousScans,
    );
  }
}
