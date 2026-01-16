/// Semantic versioning utilities for version comparison
///
/// Supports formats: "1.0.0", "v1.0.0", "1.0.0-beta"
class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;

  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
  });

  /// Parse version string like "1.0.0", "v1.0.0", "1.0.0-beta"
  factory SemanticVersion.parse(String version) {
    // Remove 'v' prefix if present
    var clean = version.trim();
    if (clean.toLowerCase().startsWith('v')) {
      clean = clean.substring(1);
    }

    // Split pre-release if present
    String? preRelease;
    if (clean.contains('-')) {
      final parts = clean.split('-');
      clean = parts[0];
      preRelease = parts.sublist(1).join('-');
    }

    // Remove build metadata if present (+xxx)
    if (clean.contains('+')) {
      clean = clean.split('+')[0];
    }

    final parts = clean.split('.');
    return SemanticVersion(
      major: int.tryParse(parts[0]) ?? 0,
      minor: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      patch: parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
      preRelease: preRelease,
    );
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Pre-release versions are less than release versions
    // e.g., 1.0.0-beta < 1.0.0
    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease == null) return -1;
    if (preRelease != null && other.preRelease != null) {
      return preRelease!.compareTo(other.preRelease!);
    }

    return 0;
  }

  /// Returns true if this version is newer than [other]
  bool isNewerThan(SemanticVersion other) => compareTo(other) > 0;

  /// Returns true if this version is older than [other]
  bool isOlderThan(SemanticVersion other) => compareTo(other) < 0;

  /// Returns true if this version equals [other]
  bool isSameAs(SemanticVersion other) => compareTo(other) == 0;

  @override
  String toString() =>
      '$major.$minor.$patch${preRelease != null ? '-$preRelease' : ''}';

  /// Returns version string with 'v' prefix
  String toTagString() => 'v$this';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticVersion &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          preRelease == other.preRelease;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);
}
