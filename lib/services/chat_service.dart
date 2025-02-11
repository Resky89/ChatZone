import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './auth_service.dart';

class ChatModel {
  final int chatId;
  final int user1Id;
  final String user1Name;
  final String? user1ProfilePicture;
  final bool user1OnlineStatus;
  final int user2Id;
  final String user2Name;
  final String? user2ProfilePicture;
  final bool user2OnlineStatus;
  final String lastMessageContent;
  final String lastMessageTime;
  final int unreadCountUser1;
  final int unreadCountUser2;
  final int lastMessageSenderId;
  final String lastMessageStatus;

  ChatModel({
    required this.chatId,
    required this.user1Id,
    required this.user1Name,
    this.user1ProfilePicture,
    required this.user1OnlineStatus,
    required this.user2Id,
    required this.user2Name,
    this.user2ProfilePicture,
    required this.user2OnlineStatus,
    required this.lastMessageContent,
    required this.lastMessageTime,
    required this.unreadCountUser1,
    required this.unreadCountUser2,
    required this.lastMessageSenderId,
    this.lastMessageStatus = 'sent',
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chat_id'],
      user1Id: json['user1_id'],
      user1Name: json['user1_name'],
      user1ProfilePicture: json['user1_profile_picture'],
      user1OnlineStatus: json['user1_online_status'] == 1,
      user2Id: json['user2_id'],
      user2Name: json['user2_name'],
      user2ProfilePicture: json['user2_profile_picture'],
      user2OnlineStatus: json['user2_online_status'] == 1,
      lastMessageContent: json['last_message_content'],
      lastMessageTime: json['last_message_time'],
      unreadCountUser1: json['unread_count_user1'],
      unreadCountUser2: json['unread_count_user2'],
      lastMessageSenderId: json['last_message_sender_id'] ?? 0,
      lastMessageStatus: json['last_message_status'] ?? 'sent',
    );
  }

  bool get isMessageFromUser2 => user2Id != user1Id;

  Map<String, dynamic> getPartnerInfo(int currentUserId) {
    if (currentUserId == user1Id) {
      return {
        'id': user2Id,
        'name': user2Name,
        'profilePicture': user2ProfilePicture,
        'onlineStatus': user2OnlineStatus,
        'isMessageFromUser2': true,
      };
    } else if (currentUserId == user2Id) {
      return {
        'id': user1Id,
        'name': user1Name,
        'profilePicture': user1ProfilePicture,
        'onlineStatus': user1OnlineStatus,
        'isMessageFromUser2': false,
      };
    } else {
      print('Warning: User ID $currentUserId tidak cocok dengan user1_id ($user1Id) atau user2_id ($user2Id)');
      return {
        'id': 0,
        'name': 'Unknown User',
        'profilePicture': null,
        'onlineStatus': false,
        'isMessageFromUser2': false,
      };
    }
  }
}

class ChatService {
  final String baseUrl;
  ChatService({this.baseUrl = 'http://10.0.2.2:3000/api'});

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AuthService.USER_ID_KEY);
  }

  Future<List<ChatModel>> getChatList() async {
    try {
      final userId = await getUserId();
      final uri = Uri.parse('$baseUrl/chat/user/$userId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> chats = responseData['data']['data'] ?? [];
        return chats.map((json) => ChatModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chat list: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createChat(Map<String, dynamic> chatData) async {
    try {
      final userId = await getUserId();
      final uri = Uri.parse('$baseUrl/chat/create');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({...chatData, 'user_id': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create chat: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateChat(
      int chatId, Map<String, dynamic> updates) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/$chatId');
      
      final Map<String, dynamic> apiUpdates = {
        'chat_id': chatId,
        ...updates,
      };

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(apiUpdates),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Debug - Error updating chat: $e');
      rethrow;
    }
  }

  Future<bool> deleteChat(int chatId) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/$chatId');

      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Debug - Error deleting chat: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPartnerInfo(int partnerId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$partnerId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get partner info');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUnreadCount(int chatId, int userId, bool isUser1) async {
    try {
      final updates = {
        'chat_id': chatId,
        isUser1 ? 'unread_count_user1' : 'unread_count_user2': 0
      };

      await updateChat(chatId, updates);
      
    } catch (e) {
      print('Debug - Error updating unread count: $e');
      rethrow;
    }
  }
}
