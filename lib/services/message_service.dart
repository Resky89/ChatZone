import 'dart:convert';
import 'package:http/http.dart' as http;

class MessageService {
  final String baseUrl = "http://10.0.2.2:3000/api";

  Future<List<Message>> getMessagesBetweenUsers(int userId1, int userId2) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/between/$userId1/$userId2'),
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body)['data'];
        return jsonData.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Message> sendMessage({
    required int senderId,
    required int receiverId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    int? replyTo,
  }) async {
    try {
      final receiverStatus = await _checkUserOnlineStatus(receiverId);
      final initialStatus = receiverStatus ? 'delivered' : 'sent';
      final timestamp = DateTime.now().toIso8601String();

      final Map<String, dynamic> messageData = {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message_content': content,
        'message_type': messageType,
        'media_url': mediaUrl,
        'timestamp': timestamp,
        'status': initialStatus,
      };

      print('Debug - Sending message data: $messageData');

      final response = await http.post(
        Uri.parse('$baseUrl/message'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(messageData),
      );

      print('Debug - Response Status: ${response.statusCode}');
      print('Debug - Response Body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Server returned status code: ${response.statusCode}');
      }

      // Create message object
      final message = Message(
        messageId: DateTime.now().millisecondsSinceEpoch,
        senderId: senderId,
        receiverId: receiverId,
        messageContent: content,
        messageType: messageType,
        mediaUrl: mediaUrl,
        timestamp: timestamp,
        status: initialStatus,
        replyTo: replyTo,
      );

      // Update chat list
      await _updateChatAfterMessage(
        senderId: senderId,
        receiverId: receiverId,
        lastMessage: content,
        timestamp: timestamp,
      );

      return message;
    } catch (e) {
      print('Debug - Send Message Error Details: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> _updateChatAfterMessage({
    required int senderId,
    required int receiverId,
    required String lastMessage,
    required String timestamp,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/chat/update-last-message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'last_message': lastMessage,
          'timestamp': timestamp,
          'increment_unread': true,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update chat list');
      }
    } catch (e) {
      print('Error updating chat after message: $e');
    }
  }

  Future<bool> deleteMessage(int messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/message/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> markMessageAsRead(int messageId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/message/$messageId/read'),
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> _checkUserOnlineStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['online_status'] == 1;
      }
      return false;
    } catch (e) {
      print('Error checking online status: $e');
      return false;
    }
  }
}

class Message {
  final int messageId;
  final int senderId;
  final int receiverId;
  final String messageContent;
  final String messageType;
  final String? mediaUrl;
  final String timestamp;
  final String status;
  final int? replyTo;

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.messageContent,
    required this.messageType,
    this.mediaUrl,
    required this.timestamp,
    required this.status,
    this.replyTo,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['message_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      messageContent: json['message_content'],
      messageType: json['message_type'],
      mediaUrl: json['media_url'],
      timestamp: json['timestamp'],
      status: json['status'],
      replyTo: json['reply_to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_content': messageContent,
      'message_type': messageType,
      'media_url': mediaUrl,
      'timestamp': timestamp,
      'status': status,
      'reply_to': replyTo,
    };
  }

  bool isFromCurrentUser(int currentUserId) {
    return senderId == currentUserId;
  }
} 