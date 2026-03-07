// lib/models/report_model.dart
class ReportModel {
  final String id;
  final String link;
  final String category;
  final String description;
  final String reporterId;
  final String reporterName;
  final DateTime reportDate;
  final int severity;
  final String? trackingNumber;
  final String? status;

  ReportModel({
    required this.id,
    required this.link,
    required this.category,
    required this.description,
    required this.reporterId,
    required this.reporterName,
    required this.reportDate,
    required this.severity,
    this.trackingNumber,
    this.status,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? json['user']?.toString() ?? '',
      reporterName: json['reporter_name']?.toString() ?? '',
      reportDate: DateTime.parse(json['created_at'] ?? json['report_date'] ?? DateTime.now().toIso8601String()),
      severity: json['severity'] ?? 3,
      trackingNumber: json['tracking_number']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'category': category,
      'description': description,
      'severity': severity,
    };
  }
}