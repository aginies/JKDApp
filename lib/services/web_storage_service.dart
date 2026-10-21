import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/series.dart';
import 'logging_service.dart';

class WebStorageService {
  static const String _baseUrl = 'https://jkd.guibo.com';
  static const String serverUrl = '$_baseUrl/api.php';
  static const String listUrl = '$_baseUrl/list.php';
  static const String downloadBaseUrl = '$_baseUrl/data/';
  static const String _tokenUrl = '$_baseUrl/token.php';

  // Supplied at build time and never committed to git:
  //   flutter build/run --dart-define=APP_SECRET=...
  // It is a client-visible shared secret (extractable from shipped binaries);
  // the real protection for uploads is the server-only TOKEN_SIGNING_KEY.
  static const String _appSecret = String.fromEnvironment('APP_SECRET');

  // Token cache — static so it survives across service instances
  static String? _cachedToken;
  static DateTime? _tokenExpiresAt;

  /// Plain HTTP client: works on native and web (XHR under the hood on web).
  ///
  /// The previous implementation bypassed TLS certificate validation
  /// (badCertificateCallback). Browsers forbid that, and the server has a
  /// valid certificate, so plain validation is used everywhere now.
  http.Client _buildClient() => http.Client();

  /// Sanitizes a user-controlled string for use as a filename component.
  ///
  /// Strips path separators, filesystem-reserved characters, control
  /// characters, and dots (replaced by `_`) so the value can never escape the
  /// upload directory, create secondary script extensions, or forge log lines
  /// — defense in depth on top of the server-side sanitization in api.php.
  static String _safeFilenamePart(String value, {int maxLength = 128}) {
    final String cleaned = value
        .replaceAll(RegExp(r'[\x00-\x1f\x7f<>:"/\\|?*.]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^_+'), '');
    final String truncated = cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
    return truncated.isEmpty ? 'untitled' : truncated;
  }

  /// Returns a valid token, fetching a new one from token.php if needed.
  Future<String> _getToken() async {
    // Reuse cached token if it has more than 60 seconds left
    if (_cachedToken != null &&
        _tokenExpiresAt != null &&
        _tokenExpiresAt!.isAfter(
          DateTime.now().add(const Duration(seconds: 60)),
        )) {
      return _cachedToken!;
    }

    LoggingService.info('WebStorageService: Fetching new token');
    final response = await _buildClient()
        .post(Uri.parse(_tokenUrl), headers: {'X-App-Secret': _appSecret})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      LoggingService.error(
        'WebStorageService: Failed to obtain token. Status: ${response.statusCode}',
      );
      throw Exception('Failed to obtain upload token (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _cachedToken = data['token'] as String;
    _tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(
      (data['expires_at'] as int) * 1000,
    );
    LoggingService.info(
      'WebStorageService: Token valid until $_tokenExpiresAt',
    );
    return _cachedToken!;
  }

  Future<List<Map<String, dynamic>>> fetchAvailableSeries() async {
    try {
      LoggingService.info(
        'WebStorageService: Fetching series list from $listUrl',
      );
      final response = await _buildClient()
          .get(Uri.parse(listUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        LoggingService.info(
          'WebStorageService: Successfully fetched ${data.length} items',
        );
        return data.cast<Map<String, dynamic>>();
      } else {
        LoggingService.error(
          'WebStorageService: Failed to fetch list. Status: ${response.statusCode}',
        );
        throw Exception('Failed to fetch series list: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error('WebStorageService: ERROR fetching list', e);
      rethrow;
    }
  }

  Future<String> downloadJson(String filename) async {
    try {
      // Create a proper URI by resolving the filename against the base URL.
      // This correctly handles special characters in the filename.
      final uri = Uri.parse(
        downloadBaseUrl,
      ).resolve(Uri.encodeComponent(filename));

      LoggingService.info('WebStorageService: Downloading $filename');
      final response = await _buildClient()
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        LoggingService.info('WebStorageService: Download success ($filename)');
        return response.body;
      } else {
        LoggingService.error(
          'WebStorageService: Download failed ($filename). Status: ${response.statusCode}',
        );
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error(
        'WebStorageService: ERROR downloading file ($filename)',
        e,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadSeries(
    JkdSeries series,
    String username,
  ) async {
    try {
      final Map<String, dynamic> seriesMap = series.toMap();
      seriesMap['moves'] = series.moves.map((m) => m.toMap()).toList();

      final String jsonContent = jsonEncode(seriesMap);

      const int maxSize = 100 * 1024;
      if (jsonContent.length > maxSize) {
        LoggingService.warn(
          'WebStorageService: Payload too large (${jsonContent.length} bytes)',
        );
        throw Exception('Series is too large to upload (max 100KB)');
      }

      final String filename = '${_safeFilenamePart(series.title)}.json';
      final String token = await _getToken();

      LoggingService.info(
        'WebStorageService: Starting upload: $filename by $username (${jsonContent.length} bytes)',
      );

      final response = await _buildClient()
          .post(
            Uri.parse(serverUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Token': token,
              'X-USERNAME': Uri.encodeComponent(username),
              'X-FILENAME': Uri.encodeComponent(filename),
              'X-CATEGORY': Uri.encodeComponent(series.category),
            },
            body: jsonContent,
          )
          .timeout(const Duration(seconds: 15));

      LoggingService.info(
        'WebStorageService: Response Status: ${response.statusCode}',
      );

      if (response.statusCode == 201) {
        LoggingService.info('WebStorageService: Upload success');
        return jsonDecode(response.body);
      } else {
        String errMsg = 'Upload failed with status ${response.statusCode}';
        try {
          if (response.headers['content-type']?.contains('application/json') ??
              false) {
            final errorBody = jsonDecode(response.body);
            errMsg = errorBody['error'] ?? errMsg;
          }
        } catch (_) {}

        LoggingService.error('WebStorageService: $errMsg');
        LoggingService.debug(
          'WebStorageService: Response Body: ${response.body}',
        );
        throw Exception(errMsg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      LoggingService.error('WebStorageService: ERROR during upload', e);
      throw Exception('Connection error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadCustomAngles(
    List<Map<String, dynamic>> anglesJson,
    String username,
  ) async {
    try {
      final String jsonContent = jsonEncode(anglesJson);

      const int maxSize = 256 * 1024; // 256KB for angles
      if (jsonContent.length > maxSize) {
        throw Exception('Custom angles file is too large (max 256KB)');
      }

      final String filename =
          'custom_angles_${_safeFilenamePart(username, maxLength: 64)}.json';
      final String token = await _getToken();

      LoggingService.info(
        'WebStorageService: Uploading custom angles: $filename',
      );

      final response = await _buildClient()
          .post(
            Uri.parse(serverUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Token': token,
              'X-USERNAME': Uri.encodeComponent(username),
              'X-FILENAME': Uri.encodeComponent(filename),
              'X-CATEGORY': Uri.encodeComponent('Custom Angles'),
            },
            body: jsonContent,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Upload failed (${response.statusCode})');
      }
    } catch (e) {
      LoggingService.error('WebStorageService: Custom angles upload error', e);
      rethrow;
    }
  }
}
