import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final String baseUrl = 'http://10.0.2.2:3000/api';

  Future<Map<String, dynamic>> getUserByPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('$baseUrl/user/phone/$phoneNumber');
      final response = await http.get(url);

      print('getUserByPhoneNumber response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        print('Response body decoded: $responseBody'); // Debug log

        // Return the entire response including status and data
        return responseBody; // Return the whole response object
      }
      throw Exception('Failed to load user');
    } catch (e) {
      print('Error in getUserByPhoneNumber: $e');
      rethrow;
    }
  }

  Future<bool> userExists(String phoneNumber) async {
    try {
      final user = await getUserByPhoneNumber(phoneNumber);
      return user.isNotEmpty;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createUser(
      String phoneNumber, String username, String profilePicturePath) async {
    try {
      print('Creating user with:');
      print('Phone: $phoneNumber');
      print('Username: $username');
      print('Profile Picture: $profilePicturePath');

      var uri = Uri.parse('$baseUrl/user');
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['phone_number'] = phoneNumber;
      request.fields['username'] = username;
      request.fields['info'] = 'Hey there! I am using ChatZone!';

      // Add profile picture if exists
      if (profilePicturePath.isNotEmpty) {
        var file = File(profilePicturePath);
        if (await file.exists()) {
          final extension = path.extension(profilePicturePath).toLowerCase();
          if (['.jpg', '.jpeg', '.png'].contains(extension)) {
            print('Adding profile picture to request');

            final mimeType = lookupMimeType(profilePicturePath);

            var stream = file.openRead();
            var length = await file.length();

            var multipartFile = http.MultipartFile(
                'profile_picture', stream, length,
                filename: path.basename(profilePicturePath),
                contentType: MediaType.parse(mimeType ?? 'image/jpeg'));

            request.files.add(multipartFile);
            print('Profile picture added to request');
            print('File name: ${multipartFile.filename}');
            print('Content type: ${multipartFile.contentType}');
          } else {
            throw Exception(
                'Invalid image format. Please use JPG, JPEG or PNG');
          }
        } else {
          print('Profile picture file does not exist');
        }
      }

      print('Sending request...');
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      print('Response status: ${streamedResponse.statusCode}');

      var response = await http.Response.fromStream(streamedResponse);
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = json.decode(response.body);
        print('Decoded response: $jsonResponse');

        if (jsonResponse['status'] == true) {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to create user');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createUser: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse('$baseUrl/user/$id');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    final url = Uri.parse('$baseUrl/user/$id');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  Future<void> updateOnlineStatus(String id, bool onlineStatus) async {
    final url = Uri.parse('$baseUrl/user/$id/online-status');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'online_status': onlineStatus ? 1 : 0}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update online status');
    }
  }

  Future<void> saveUserPhone(String phoneNumber, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phoneNumber);
    await prefs.setInt('user_id', userId);
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/user/$userId');
      final response = await http.get(url);

      print('getUserById response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        print('Response body decoded: $responseBody'); // Debug log

        return responseBody;
      }
      throw Exception('Failed to load user');
    } catch (e) {
      print('Error in getUserById: $e');
      rethrow;
    }
  }

  Future<void> updateUserWithImage(String id, Map<String, dynamic> userData,
      {File? imageFile}) async {
    try {
      final url = Uri.parse('$baseUrl/user/$id');
      var request = http.MultipartRequest('PUT', url);

      // Get current user data first
      final currentUserData = await getUserById(int.parse(id));
      final currentUser = currentUserData['data'];

      // Merge current data with new data, keeping existing values if not updated
      final mergedData = {
        'username': userData['username'] ?? currentUser['username'],
        'phone_number': currentUser['phone_number'],
        'info': userData['info'] ?? currentUser['info'],
        'profile_picture': currentUser['profile_picture'],
      };

      // Add merged user data to request
      mergedData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add image file if provided
      if (imageFile != null) {
        final extension = path.extension(imageFile.path).toLowerCase();
        if (['.jpg', '.jpeg', '.png'].contains(extension)) {
          final mimeType = lookupMimeType(imageFile.path);

          var stream = imageFile.openRead();
          var length = await imageFile.length();

          var multipartFile = http.MultipartFile(
              'profile_picture', stream, length,
              filename: path.basename(imageFile.path),
              contentType: MediaType.parse(mimeType ?? 'image/jpeg'));

          request.files.add(multipartFile);
        } else {
          throw Exception('Invalid image format. Please use JPG, JPEG or PNG');
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }
}
