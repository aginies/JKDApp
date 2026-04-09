import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import '../models/series.dart';

class WebStorageService {
  // TODO: Replace with your actual server URL in production
  static const String serverUrl = 'https://ftp.guibo.com/api.php';
  static const String listUrl = 'https://ftp.guibo.com/list.php';
  static const String downloadBaseUrl = 'https://ftp.guibo.com/data/';
  static const String apiKey = 'jkd_secure_upload_key_888';

  Future<List<Map<String, dynamic>>> fetchAvailableSeries() async {
    try {
      final HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      final IOClient ioClient = IOClient(httpClient);

      final response = await ioClient
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
      final HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      final IOClient ioClient = IOClient(httpClient);

      final response = await ioClient
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
      // Ensure moves are included in the map for backup
      seriesMap['moves'] = series.moves.map((m) => m.toMap()).toList();

      final String jsonContent = jsonEncode(seriesMap);
      
      // Limit upload to 100 KB (100,000 bytes)
      const int maxSize = 100 * 1024;
      if (jsonContent.length > maxSize) {
        throw Exception('Series is too large to upload (max 100KB)');
      }

      // Use the original title as the filename (sanitized only for filesystem safety)
      final String filename = '${series.title}.json';

      debugPrint('WebStorageService: Starting upload to $serverUrl');
      debugPrint('WebStorageService: Filename: $filename, User: $username');
      debugPrint('WebStorageService: Payload size: ${jsonContent.length} bytes');

      // Create a client that ignores SSL certificate errors
      final HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      final IOClient ioClient = IOClient(httpClient);

      final response = await ioClient
          .post(
            Uri.parse(serverUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-API-KEY': apiKey,
              'X-USERNAME': username,
              'X-FILENAME': filename,
              'X-CATEGORY': series.category,
            },
            body: jsonContent,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('WebStorageService: Response Status: ${response.statusCode}');
      debugPrint('WebStorageService: Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        // Safely try to parse JSON error, otherwise return raw body
        try {
          if (response.headers['content-type']?.contains('application/json') ?? false) {
            final errorBody = jsonDecode(response.body);
            throw Exception(errorBody['error'] ?? 'Upload failed with status ${response.statusCode}');
          } else {
            throw Exception('Server returned status ${response.statusCode}. (Non-JSON response)');
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
