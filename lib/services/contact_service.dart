import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ContactService {
  final String baseUrl = 'http://10.0.2.2:3000/api';
  final AuthService _authService = AuthService();

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AuthService.USER_ID_KEY);
  }

  Future<List<ContactModel>> getContacts(int userId) async {
    try {
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId != userId) {
        throw Exception('Unauthorized access');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/contacts'),
      );

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> contacts = responseData['data']['data'] ?? [];
        return contacts.map((json) => ContactModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load contacts: ${response.statusCode}');
    } catch (e) {
      print('Error getting contacts: $e');
      rethrow;
    }
  }

  Future<void> addContact(int userId, int contactId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/contacts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'contact_id': contactId}),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add contact');
      }
    } catch (e) {
      print('Error adding contact: $e');
      rethrow;
    }
  }

  Future<void> deleteContact(int userId, int contactId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/contacts/$contactId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete contact');
      }
    } catch (e) {
      print('Error deleting contact: $e');
      rethrow;
    }
  }
}

class ContactModel {
  final int userId;
  final int contactUserId;
  final String username;
  final String? profilePicture;
  final String info;
  final bool onlineStatus;

  ContactModel({
    required this.userId,
    required this.contactUserId,
    required this.username,
    this.profilePicture,
    required this.info,
    this.onlineStatus = false,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      userId: json['user_id'],
      contactUserId: json['contact_user_id'],
      username: json['nickname'] ?? '',
      profilePicture: json['profile_picture'],
      info: json['info'] ?? 'Hey there! I am using ChatZone!',
      onlineStatus: json['online_status'] == 1,
    );
  }
} 