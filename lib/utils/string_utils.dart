/// Utility class for string manipulation across the app
class StringUtils {
  /// Converts a string to a URL-friendly slug
  /// Example: "Hook Kick" -> "hook-kick"
  static String slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
