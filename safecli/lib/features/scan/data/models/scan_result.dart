// lib/features/scan/data/models/scan_result.dart
// Data model for scan results — mirrors ScanEntity with JSON serialization.
import 'package:safeclik/features/scan/domain/entities/scan_entity.dart';

class ScanResult {
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

  const ScanResult({
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
    this.source = 'سيرفر SafeClick',
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id']?.toString() ?? 'scan_${DateTime.now().millisecondsSinceEpoch}',
      link: json['link']?.toString() ?? json['url']?.toString() ?? '',
      safe: json['safe'] as bool?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
      details: json['details'] != null
          ? List<String>.from(json['details'])
          : <String>[],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      rawData: json['rawData'] as Map<String, dynamic>?,
      responseTime: (json['responseTime'] as num?)?.toDouble() ?? 0.0,
      ipAddress: json['ipAddress']?.toString(),
      domain: json['domain']?.toString(),
      threatsCount: (json['threats_count'] as num?)?.toInt(),
      source: json['source']?.toString() ?? 'سيرفر SafeClick',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'link': link,
      'safe': safe,
      'score': score,
      'message': message,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'rawData': rawData,
      'responseTime': responseTime,
      'ipAddress': ipAddress,
      'domain': domain,
      'threatsCount': threatsCount,
      'source': source,
    };
  }

  ScanEntity toEntity() {
    return ScanEntity(
      id: id,
      link: link,
      safe: safe,
      score: score,
      message: message,
      details: details,
      timestamp: timestamp,
      rawData: rawData,
      responseTime: responseTime,
      ipAddress: ipAddress,
      domain: domain,
      threatsCount: threatsCount,
      source: source,
    );
  }

  String get safetyStatus {
    if (safe == true) return 'آمن';
    if (safe == false) return 'خطير';
    return 'مشبوه';
  }
}
