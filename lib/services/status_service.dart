import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart' show lookupMimeType;

class StatusService {
  final String baseUrl = 'http://10.0.2.2:3000/api';

  // Get My Status
  Future<List<dynamic>> getMyStatuses(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/own-statuses'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['data']['statuses'] ?? [];
      }
      throw Exception('Failed to load my statuses');
    } catch (e) {
      print('Error getting my statuses: $e');
      rethrow;
    }
  }

  // Post Status
  Future<void> postStatus(String userId, String mediaPath,
      {String? caption}) async {
    try {
      var uri = Uri.parse('$baseUrl/statuses');
      var request = http.MultipartRequest('POST', uri);

      // Debug print
      print('Creating status with:');
      print('User ID: $userId');
      print('Caption: $caption');
      print('Media Path: $mediaPath');

      // Add fields
      request.fields['user_id'] = userId;
      if (caption != null && caption.isNotEmpty) {
        request.fields['text_caption'] = caption;
      }

      // Add media file
      var file = File(mediaPath);
      var stream = file.openRead();
      var length = await file.length();
      var mimeType = lookupMimeType(mediaPath) ?? 'image/jpeg';

      print('Adding media to request');
      var multipartFile = http.MultipartFile(
          'media_url', // Harus sama dengan field name di multer
          stream,
          length,
          filename: path.basename(mediaPath),
          contentType: MediaType.parse(mimeType));
      request.files.add(multipartFile);
      print('Media added to request');

      // Send request
      var response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 201) {
        // Server mengembalikan 201 untuk created
        return;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in postStatus: $e');
      rethrow;
    }
  }

  // Delete Status
  Future<void> deleteStatus(String statusId) async {
    try {
      print('Attempting to delete status with ID: $statusId'); // Debug print

      final response = await http.delete(
        Uri.parse('$baseUrl/statuses/$statusId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print(
          'Delete response status code: ${response.statusCode}'); // Debug print
      print('Delete response body: ${response.body}'); // Debug print

      if (response.statusCode != 200) {
        throw Exception('Failed to delete status: ${response.body}');
      }
    } catch (e) {
      print('Error deleting status: $e');
      rethrow;
    }
  }

  // Get User Status by ID
  Future<List<dynamic>> getUserStatuses(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/own-statuses'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['data'] ?? [];
      }
      throw Exception('Failed to load user statuses');
    } catch (e) {
      print('Error getting user statuses: $e');
      rethrow;
    }
  }

  // Get Other Statuses
  Future<List<dynamic>> getOtherStatuses(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/contact-statuses'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['data']['statuses'] ?? [];
      }
      throw Exception('Failed to load other statuses');
    } catch (e) {
      print('Error getting other statuses: $e');
      rethrow;
    }
  }
}
