class SettingsModel {
  bool autoScan;
  bool notifications;
  bool deepLinks;
  String language;
  bool safeBrowsing;
  bool darkMode;
  bool autoUpdate;
  bool saveHistory;
  String scanLevel; // 'basic', 'standard', 'deep'

  SettingsModel({
    this.autoScan = true,
    this.notifications = true,
    this.deepLinks = true,
    this.language = 'ar',
    this.safeBrowsing = true,
    this.darkMode = false,
    this.autoUpdate = true,
    this.saveHistory = true,
    this.scanLevel = 'basic',
  });

  Map<String, dynamic> toJson() => {
        'autoScan': autoScan,
        'notifications': notifications,
        'deepLinks': deepLinks,
        'language': language,
        'safeBrowsing': safeBrowsing,
        'darkMode': darkMode,
        'autoUpdate': autoUpdate,
        'saveHistory': saveHistory,
        'scanLevel': scanLevel,
      };

  factory SettingsModel.fromJson(Map<String, dynamic> json) => SettingsModel(
        autoScan: json['autoScan'] ?? true,
        notifications: json['notifications'] ?? true,
        deepLinks: json['deepLinks'] ?? true,
        language: json['language'] ?? 'ar',
        safeBrowsing: json['safeBrowsing'] ?? true,
        darkMode: json['darkMode'] ?? false,
        autoUpdate: json['autoUpdate'] ?? true,
        saveHistory: json['saveHistory'] ?? true,
        scanLevel: json['scanLevel'] ?? 'basic',
      );

  SettingsModel copyWith({
    bool? autoScan,
    bool? notifications,
    bool? deepLinks,
    String? language,
    bool? safeBrowsing,
    bool? darkMode,
    bool? autoUpdate,
    bool? saveHistory,
    String? scanLevel,
  }) {
    return SettingsModel(
      autoScan: autoScan ?? this.autoScan,
      notifications: notifications ?? this.notifications,
      deepLinks: deepLinks ?? this.deepLinks,
      language: language ?? this.language,
      safeBrowsing: safeBrowsing ?? this.safeBrowsing,
      darkMode: darkMode ?? this.darkMode,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      saveHistory: saveHistory ?? this.saveHistory,
      scanLevel: scanLevel ?? this.scanLevel,
    );
  }
}
