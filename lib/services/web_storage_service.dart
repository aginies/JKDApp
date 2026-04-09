import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import '../models/series.dart';

class WebStorageService {
  static const String _baseUrl        = 'https://ftp.guibo.com';
  static const String serverUrl       = '$_baseUrl/api.php';
  static const String listUrl         = '$_baseUrl/list.php';
  static const String downloadBaseUrl = '$_baseUrl/data/';
  static const String _tokenUrl       = '$_baseUrl/token.php';
  static const String _appSecret      = 'jkd_secure_upload_key_888';

  // Token cache — static so it survives across service instances
  static String?   _cachedToken;
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
        _tokenExpiresAt!.isAfter(DateTime.now().add(const Duration(seconds: 60)))) {
      return _cachedToken!;
    }

    debugPrint('WebStorageService: Fetching new token');
    final response = await _buildClient()
        .post(
          Uri.parse(_tokenUrl),
          headers: {'X-App-Secret': _appSecret},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to obtain upload token (${response.statusCode})');
    }

    final data      = jsonDecode(response.body) as Map<String, dynamic>;
    _cachedToken    = data['token'] as String;
    _tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(
      (data['expires_at'] as int) * 1000,
    );
    debugPrint('WebStorageService: Token valid until $_tokenExpiresAt');
    return _cachedToken!;
  }

  Future<List<Map<String, dynamic>>> fetchAvailableSeries() async {
    try {
      final response = await _buildClient()
          .get(Uri.parse(listUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch series list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('WebStorageService: ERROR fetching list: $e');
      rethrow;
    }
  }

  Future<String> downloadJson(String filename) async {
    try {
      final response = await _buildClient()
          .get(Uri.parse('$downloadBaseUrl$filename'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('WebStorageService: ERROR downloading file: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadSeries(JkdSeries series, String username) async {
    try {
      final Map<String, dynamic> seriesMap = series.toMap();
      seriesMap['moves'] = series.moves.map((m) => m.toMap()).toList();

      final String jsonContent = jsonEncode(seriesMap);

      const int maxSize = 100 * 1024;
      if (jsonContent.length > maxSize) {
        throw Exception('Series is too large to upload (max 100KB)');
      }

      final String filename = '${series.title}.json';
      final String token    = await _getToken();

      debugPrint('WebStorageService: Starting upload to $serverUrl');
      debugPrint('WebStorageService: Filename: $filename, User: $username');
      debugPrint('WebStorageService: Payload size: ${jsonContent.length} bytes');

      final response = await _buildClient()
          .post(
            Uri.parse(serverUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Token':      token,
              'X-USERNAME':   username,
              'X-FILENAME':   filename,
              'X-CATEGORY':   series.category,
            },
            body: jsonContent,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('WebStorageService: Response Status: ${response.statusCode}');
      debugPrint('WebStorageService: Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        try {
          if (response.headers['content-type']?.contains('application/json') ?? false) {
            final errorBody = jsonDecode(response.body);
            throw Exception(
              errorBody['error'] ?? 'Upload failed with status ${response.statusCode}',
            );
          } else {
            throw Exception(
              'Server returned status ${response.statusCode}. (Non-JSON response)',
            );
          }
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Upload failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('WebStorageService: ERROR during upload: $e');
      throw Exception('Connection error: $e');
    }
  }
}
