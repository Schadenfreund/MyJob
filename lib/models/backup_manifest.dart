/// Backup manifest model for validation and version compatibility
class BackupManifest {
  final String backupVersion;
  final String appVersion;
  final DateTime timestamp;
  final BackupStats stats;

  BackupManifest({
    required this.appVersion,
    required this.timestamp,
    required this.stats,
    this.backupVersion = '1.0',
  });

  Map<String, dynamic> toJson() {
    return {
      'backupVersion': backupVersion,
      'appVersion': appVersion,
      'timestamp': timestamp.toIso8601String(),
      'stats': stats.toJson(),
    };
  }

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      backupVersion: json['backupVersion'] as String? ?? '1.0',
      appVersion: json['appVersion'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      stats: BackupStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }
}

/// Statistics about the backup contents
class BackupStats {
  final int applicationCount;
  final int profileCount;
  final int noteCount;
  final int totalFiles;

  BackupStats({
    required this.applicationCount,
    required this.profileCount,
    required this.noteCount,
    required this.totalFiles,
  });

  Map<String, dynamic> toJson() {
    return {
      'applicationCount': applicationCount,
      'profileCount': profileCount,
      'noteCount': noteCount,
      'totalFiles': totalFiles,
    };
  }

  factory BackupStats.fromJson(Map<String, dynamic> json) {
    return BackupStats(
      applicationCount: json['applicationCount'] as int? ?? 0,
      profileCount: json['profileCount'] as int? ?? 0,
      noteCount: json['noteCount'] as int? ?? 0,
      totalFiles: json['totalFiles'] as int? ?? 0,
    );
  }
}
