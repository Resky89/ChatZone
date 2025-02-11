import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/message_service.dart';
import '../services/chat_service.dart';
import 'dart:math' show min;

class ChattingPage extends StatefulWidget {
  final int chatId;
  final String name;
  final int partnerId;

  const ChattingPage({
    super.key,
    required this.chatId,
    required this.name,
    required this.partnerId,
  });

  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  final Color primaryPurple = const Color(0xFF6200EE);
  final Color lightPurple = const Color(0xFFBB86FC);
  final Color backgroundColor = const Color(0xFFECE5DD);

  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool isOnline = true; // Tambahkan variabel ini untuk status online

  final MessageService _messageService = MessageService();
  final ChatService _chatService = ChatService();
  bool isLoading = true;
  late int currentUserId;

  final ScrollController _scrollController = ScrollController();

  String? profilePicture;
  String? lastSeen;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadUserProfile();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => isLoading = true);
      
      // Get current user ID
      currentUserId = await _chatService.getUserId() ?? 0;
      
      // Get messages between current user and partner
      final messages = await _messageService.getMessagesBetweenUsers(
        currentUserId,      // Current user ID
        widget.partnerId,   // Partner ID (bukan chat ID)
      );
      
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages.map((message) => 
            ChatMessage(
              text: message.messageContent,
              isMe: message.senderId == currentUserId,
              time: _parseDateTime(message.timestamp),
              status: _getMessageStatus(message.status),
            )
          ).toList());
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userData = await _chatService.getPartnerInfo(widget.partnerId);
      print('User Profile Data: $userData'); // Debug log

      if (mounted) {
        setState(() {
          final data = userData['data'];
          profilePicture = data['profile_picture'];
          isOnline = data['online_status'] == 1;
          
          if (!isOnline && data['last_seen'] != null) {
            try {
              lastSeen = DateFormat('dd/MM/yyyy HH:mm').format(
                _parseDateTime(data['last_seen'])
              );
            } catch (e) {
              print('Error parsing last_seen: $e');
              lastSeen = 'Recently';
            }
          }
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Add helper method to parse timestamp
  DateTime _parseDateTime(String timestamp) {
    List<String> parts = timestamp.split(' ');
    List<String> dateParts = parts[0].split('-');
    List<String> timeParts = parts[1].split(':');
    
    return DateTime(
      int.parse(dateParts[2]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[0]), // day
      int.parse(timeParts[0]), // hour
      int.parse(timeParts[1]), // minute
      int.parse(timeParts[2]), // second
    );
  }

  MessageStatus _getMessageStatus(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }

  // Update _handleSubmitted to send message to correct receiver
  void _handleSubmitted() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      // Clear text field immediately
      _messageController.clear();

      // Send message first
      await _messageService.sendMessage(
        senderId: currentUserId,
        receiverId: widget.partnerId,
        content: messageText,
      );

      // After successful send, update UI
      if (mounted) {
        setState(() {
          // Ubah dari insert(0) menjadi add() untuk menambahkan di akhir list
          _messages.add(ChatMessage(
            text: messageText,
            isMe: true,
            time: DateTime.now(),
            status: MessageStatus.sent,
          ));
        });

        // Scroll ke posisi paling bawah setelah menambah pesan
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );

        _loadMessages();
      }

    } catch (e) {
      print('Debug - Send Message Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _messageController.text = messageText;
                _handleSubmitted();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.primaries[widget.partnerId % Colors.primaries.length],
              backgroundImage: profilePicture != null && profilePicture!.isNotEmpty
                  ? NetworkImage('http://10.0.2.2:3000/media/profile_pictures/$profilePicture')
                  : null,
              child: (profilePicture == null || profilePicture!.isEmpty)
                  ? Text(
                      widget.name
                          .split(' ')
                          .map((word) => word[0].toUpperCase())
                          .join('')
                          .substring(0, min(2, widget.name.split(' ').length)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  _buildUserStatus(),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                image: const DecorationImage(
                  image: AssetImage('assets/chat_background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
              child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe ? lightPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 0),
            bottomRight: Radius.circular(message.isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.time),
                  style: TextStyle(
                    color: message.isMe ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                if (message.isMe) ...[
                  const SizedBox(width: 4),
                  _buildMessageStatus(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatus(MessageStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white70;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white70;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
    }

    return Icon(icon, size: 16, color: color);
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.emoji_emotions, color: primaryPurple),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.attach_file, color: primaryPurple),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.camera_alt, color: primaryPurple),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.send, color: primaryPurple),
            onPressed: _handleSubmitted,
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatus() {
    if (isOnline) {
      return const Text(
        'Online',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      );
    } else {
      return Text(
        lastSeen != null ? 'Last seen $lastSeen' : 'Offline',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      );
    }
  }
}

enum MessageStatus { sent, delivered, read }

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  final MessageStatus status;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    required this.status,
  });
}
