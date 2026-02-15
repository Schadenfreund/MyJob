/// Base exception for all backup-related errors
class BackupException implements Exception {
  final String message;

  BackupException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when backup validation fails
class BackupValidationException extends BackupException {
  BackupValidationException(String message) : super(message);
}

/// Exception thrown when there's insufficient disk space
class BackupDiskFullException extends BackupException {
  final int requiredBytes;
  final int availableBytes;

  BackupDiskFullException(this.requiredBytes, this.availableBytes)
      : super('Insufficient disk space');

  @override
  String toString() {
    final requiredMB = (requiredBytes / 1024 / 1024).toStringAsFixed(0);
    final availableMB = (availableBytes / 1024 / 1024).toStringAsFixed(0);
    return 'Insufficient disk space. Need ${requiredMB}MB, only ${availableMB}MB available.';
  }
}

/// Exception thrown when file permissions prevent backup/restore
class BackupPermissionException extends BackupException {
  final String path;

  BackupPermissionException(this.path) : super('Permission denied: $path');

  @override
  String toString() =>
      'Permission denied. Try selecting a different folder or run as administrator.';
}

/// Exception thrown when backup file is corrupted
class BackupCorruptedException extends BackupException {
  BackupCorruptedException() : super('Backup file is corrupted');

  @override
  String toString() =>
      'Backup file is corrupted. Please try a different backup file.';
}
