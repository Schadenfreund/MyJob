import 'dart:convert';

/// Centralized JSON encoding constants
///
/// Provides consistent JSON formatting across all services that persist data.
class JsonConstants {
  JsonConstants._();

  /// Pretty-printed JSON encoder with 2-space indentation
  ///
  /// Use this for all JSON file serialization to ensure consistent,
  /// human-readable formatting across the application.
  static const JsonEncoder prettyEncoder = JsonEncoder.withIndent('  ');
}
