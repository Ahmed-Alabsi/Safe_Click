class SettingsModel {
  bool autoScan;
  bool notifications;
  String language;
  bool safeBrowsing;
  bool darkMode;
  bool autoUpdate;
  bool saveHistory;
  int scanTimeout;
  String scanLevel; // 'basic', 'standard', 'deep'

  SettingsModel({
    this.autoScan = true,
    this.notifications = true,
    this.language = 'ar',
    this.safeBrowsing = true,
    this.darkMode = false,
    this.autoUpdate = true,
    this.saveHistory = true,
    this.scanTimeout = 30,
    this.scanLevel = 'standard',
  });

  Map<String, dynamic> toJson() => {
        'autoScan': autoScan,
        'notifications': notifications,
        'language': language,
        'safeBrowsing': safeBrowsing,
        'darkMode': darkMode,
        'autoUpdate': autoUpdate,
        'saveHistory': saveHistory,
        'scanTimeout': scanTimeout,
        'scanLevel': scanLevel,
      };

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
        autoScan: json['autoScan'] ?? true,
        notifications: json['notifications'] ?? true,
        language: json['language'] ?? 'ar',
        safeBrowsing: json['safeBrowsing'] ?? true,
        darkMode: json['darkMode'] ?? false,
        autoUpdate: json['autoUpdate'] ?? true,
        saveHistory: json['saveHistory'] ?? true,
        scanTimeout: json['scanTimeout'] ?? 30,
        scanLevel: json['scanLevel'] ?? 'standard',
      );

  SettingsModel copyWith({
    bool? autoScan,
    bool? notifications,
    String? language,
    bool? safeBrowsing,
    bool? darkMode,
    bool? autoUpdate,
    bool? saveHistory,
    int? scanTimeout,
    String? scanLevel,
  }) {
    return SettingsModel(
      autoScan: autoScan ?? this.autoScan,
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
      safeBrowsing: safeBrowsing ?? this.safeBrowsing,
      darkMode: darkMode ?? this.darkMode,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      saveHistory: saveHistory ?? this.saveHistory,
      scanTimeout: scanTimeout ?? this.scanTimeout,
      scanLevel: scanLevel ?? this.scanLevel,
    );
  }
}
