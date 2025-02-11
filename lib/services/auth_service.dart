import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthService {
  static const String PHONE_KEY = 'phone_number';
  static const String USER_ID_KEY = 'user_id';
  
  Future<Map<String, dynamic>> saveUserPhone(String phoneNumber, int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (userId <= 0) {
        throw Exception('Invalid user ID');
      }

      await Future.wait([
        prefs.setString(PHONE_KEY, phoneNumber),
        prefs.setInt(USER_ID_KEY, userId),
      ]);
      
      print('Attempting to save - Phone: $phoneNumber, ID: $userId');

      final savedPhone = prefs.getString(PHONE_KEY);
      final savedUserId = prefs.getInt(USER_ID_KEY);

      print('Verification - Saved Phone: $savedPhone, Saved ID: $savedUserId');

      if (savedPhone == null || savedUserId == null) {
        throw Exception('Failed to save user data');
      }

      return {
        'phone': savedPhone,
        'userId': savedUserId,
        'success': true
      };
    } catch (e) {
      debugPrint('SharedPreferences error: $e');
      throw Exception('Unable to save login information: $e');
    }
  }

  Future<String?> getLoggedInUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PHONE_KEY);
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PHONE_KEY);
      await prefs.remove(USER_ID_KEY);
      print('Logged out - Cleared all user data');
    } catch (e) {
      debugPrint('Logout error: $e');
      throw Exception('Unable to logout. Please try again.');
    }
  }

  Future<int> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(USER_ID_KEY);
      
      if (userId == null) {
        throw Exception('User ID not found');
      }
      return userId;
    } catch (e) {
      debugPrint('Get user ID error: $e');
      throw Exception('Failed to get user ID: $e');
    }
  }

  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PHONE_KEY);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
} 