import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import '../models/series.dart';
import 'logging_service.dart';

class WebStorageService {
  static const String _baseUrl = 'https://jkd.guibo.com';
  static const String serverUrl = '$_baseUrl/api.php';
  static const String listUrl = '$_baseUrl/list.php';
  static const String downloadBaseUrl = '$_baseUrl/data/';
  static const String _tokenUrl = '$_baseUrl/token.php';
  static const String _appSecret = 'iada9426bf7aa6e5aa52d00fda4f426f08eefe19cd9a0c3a6e7ca719f11eaffaf';

  // Token cache — static so it survives across service instances
  static String? _cachedToken;
  static DateTime? _tokenExpiresAt;

  IOClient _buildClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
    return IOClient(httpClient);
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
      LoggingService.error('WebStorageService: Failed to obtain token. Status: ${response.statusCode}');
      throw Exception('Failed to obtain upload token (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _cachedToken = data['token'] as String;
    _tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(
      (data['expires_at'] as int) * 1000,
    );
    LoggingService.info('WebStorageService: Token valid until $_tokenExpiresAt');
    return _cachedToken!;
  }

  Future<List<Map<String, dynamic>>> fetchAvailableSeries() async {
    try {
      LoggingService.info('WebStorageService: Fetching series list from $listUrl');
      final response = await _buildClient()
          .get(Uri.parse(listUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        LoggingService.info('WebStorageService: Successfully fetched ${data.length} items');
        return data.cast<Map<String, dynamic>>();
      } else {
        LoggingService.error('WebStorageService: Failed to fetch list. Status: ${response.statusCode}');
        throw Exception('Failed to fetch series list: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error('WebStorageService: ERROR fetching list', e);
      rethrow;
    }
  }

  Future<String> downloadJson(String filename) async {
    try {
      LoggingService.info('WebStorageService: Downloading $filename');
      final response = await _buildClient()
          .get(Uri.parse('$downloadBaseUrl$filename'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        LoggingService.info('WebStorageService: Download success ($filename)');
        return response.body;
      } else {
        LoggingService.error('WebStorageService: Download failed ($filename). Status: ${response.statusCode}');
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error('WebStorageService: ERROR downloading file ($filename)', e);
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
        LoggingService.warn('WebStorageService: Payload too large (${jsonContent.length} bytes)');
        throw Exception('Series is too large to upload (max 100KB)');
      }

      final String filename = '${series.title}.json';
      final String token = await _getToken();

      LoggingService.info('WebStorageService: Starting upload: $filename by $username (${jsonContent.length} bytes)');

      final response = await _buildClient()
          .post(
            Uri.parse(serverUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Token': token,
              'X-USERNAME': username,
              'X-FILENAME': filename,
              'X-CATEGORY': series.category,
            },
            body: jsonContent,
          )
          .timeout(const Duration(seconds: 15));

      LoggingService.info('WebStorageService: Response Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        LoggingService.info('WebStorageService: Upload success');
        return jsonDecode(response.body);
      } else {
        String errMsg = 'Upload failed with status ${response.statusCode}';
        try {
          if (response.headers['content-type']?.contains('application/json') ?? false) {
            final errorBody = jsonDecode(response.body);
            errMsg = errorBody['error'] ?? errMsg;
          }
        } catch (_) {}
        
        LoggingService.error('WebStorageService: $errMsg');
        LoggingService.debug('WebStorageService: Response Body: ${response.body}');
        throw Exception(errMsg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      LoggingService.error('WebStorageService: ERROR during upload', e);
      throw Exception('Connection error: $e');
    }
  }
}
