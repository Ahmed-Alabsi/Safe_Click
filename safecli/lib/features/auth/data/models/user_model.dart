// lib/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final int scannedLinks;
  final int detectedThreats;
  final double accuracyRate;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.scannedLinks = 0,
    this.detectedThreats = 0,
    this.accuracyRate = 0.0,
    this.isEmailVerified = false,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profile_image']?.toString(),
      scannedLinks: json['scanned_links'] ?? 0,
      detectedThreats: json['detected_threats'] ?? 0,
      accuracyRate: (json['accuracy_rate'] ?? 0.0).toDouble(),
      isEmailVerified: json['is_email_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image': profileImage,
      'scanned_links': scannedLinks,
      'detected_threats': detectedThreats,
      'accuracy_rate': accuracyRate,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  // أضف هذه الدالة
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    int? scannedLinks,
    int? detectedThreats,
    double? accuracyRate,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      scannedLinks: scannedLinks ?? this.scannedLinks,
      detectedThreats: detectedThreats ?? this.detectedThreats,
      accuracyRate: accuracyRate ?? this.accuracyRate,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // دالة مساعدة للحصول على رابط الصورة الكامل
  String? get fullProfileImageUrl {
    if (profileImage == null) return null;
    if (profileImage!.startsWith('http')) return profileImage;
    return 'http://192.168.8.110:8000$profileImage';
  }
}