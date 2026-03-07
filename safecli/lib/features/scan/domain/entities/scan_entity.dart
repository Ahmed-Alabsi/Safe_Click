// lib/features/scan/domain/entities/scan_entity.dart
// Pure Dart — NO Flutter imports.

class ScanEntity {
  final String id;
  final String link;
  final bool? safe;
  final int score;
  final String message;
  final List<String> details;
  final DateTime timestamp;
  final Map<String, dynamic>? rawData;
  final double responseTime;
  final String? ipAddress;
  final String? domain;
  final int? threatsCount;
  final String source;

  const ScanEntity({
    required this.id,
    required this.link,
    this.safe,
    required this.score,
    required this.message,
    required this.details,
    required this.timestamp,
    this.rawData,
    this.responseTime = 0.0,
    this.ipAddress,
    this.domain,
    this.threatsCount,
    this.source = 'SafeClick Server',
  });

  /// Pure string status — no Flutter dependency.
  String get safetyStatus {
    if (safe == true) return 'آمن';
    if (safe == false) return 'خطير';
    return 'مشبوه';
  }
}
