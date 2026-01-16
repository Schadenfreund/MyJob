/// Update information from GitHub releases
class UpdateInfo {
  final String version;
  final String tagName;
  final String downloadUrl;
  final String changelog;
  final int downloadSize;
  final DateTime publishedAt;
  final String? checksumUrl;

  const UpdateInfo({
    required this.version,
    required this.tagName,
    required this.downloadUrl,
    required this.changelog,
    required this.downloadSize,
    required this.publishedAt,
    this.checksumUrl,
  });

  /// Parse from GitHub releases API response
  factory UpdateInfo.fromGitHubRelease(Map<String, dynamic> json) {
    final assets = (json['assets'] as List?) ?? [];

    // Find the Windows ZIP asset
    final windowsAsset = assets.firstWhere(
      (a) =>
          (a['name'] as String?)?.toLowerCase().contains('windows') == true &&
          (a['name'] as String?)?.toLowerCase().endsWith('.zip') == true,
      orElse: () => <String, dynamic>{},
    );

    // Find checksum file if exists
    final checksumAsset = assets.firstWhere(
      (a) => (a['name'] as String?)?.toLowerCase().endsWith('.sha256') == true,
      orElse: () => <String, dynamic>{},
    );

    final tagName = json['tag_name'] as String? ?? '';
    // Remove 'v' prefix from tag for version number
    final version =
        tagName.startsWith('v') ? tagName.substring(1) : tagName;

    return UpdateInfo(
      version: version,
      tagName: tagName,
      downloadUrl: windowsAsset['browser_download_url'] as String? ?? '',
      changelog: json['body'] as String? ?? '',
      downloadSize: windowsAsset['size'] as int? ?? 0,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '') ??
          DateTime.now(),
      checksumUrl: checksumAsset['browser_download_url'] as String?,
    );
  }

  /// Check if this update has a valid download URL
  bool get hasValidDownload => downloadUrl.isNotEmpty;

  /// Human-readable download size
  String get formattedSize {
    if (downloadSize < 1024) return '$downloadSize B';
    if (downloadSize < 1024 * 1024) {
      return '${(downloadSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(downloadSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format the published date
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(publishedAt);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${publishedAt.day}.${publishedAt.month}.${publishedAt.year}';
  }
}

/// State of the update process
enum UpdateState {
  idle('Ready to check'),
  checking('Checking for updates...'),
  upToDate('Up to date'),
  available('Update available'),
  downloading('Downloading update...'),
  extracting('Preparing update...'),
  readyToInstall('Ready to install'),
  installing('Installing...'),
  error('Update failed');

  const UpdateState(this.label);
  final String label;

  bool get isLoading =>
      this == checking || this == downloading || this == extracting;
  bool get canCheck => this == idle || this == upToDate || this == error;
  bool get canDownload => this == available;
  bool get canInstall => this == readyToInstall;
}
