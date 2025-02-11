import 'package:flutter/material.dart';
import 'dart:async';
import 'profile.dart';
import 'chatting.dart';
import '../app/register.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'contact_list.dart';
import 'dart:math' show min;
import 'package:shimmer/shimmer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  List<ChatModel> chatList = [];
  bool isLoading = true;
  int currentUserId = 0;
  Timer? _refreshTimer;

  // Original colors
  final Color primaryPurple = const Color(0xFF6200EE);
  final Color lightPurple = const Color(0xFFBB86FC);

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Set up periodic refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadChatList();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel timer when disposing
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final userId = await _chatService.getUserId() ?? 0;
    if (mounted) {
      setState(() {
        currentUserId = userId;
      });
    }
    _loadChatList();
  }

  Future<void> _loadChatList() async {
    try {
      final chats = await _chatService.getChatList();
      if (mounted) {
        setState(() {
          chatList = chats;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleChatOpen(
      ChatModel chat, Map<String, dynamic> partnerInfo) async {
    try {
      if (currentUserId == chat.user1Id) {
        if (chat.unreadCountUser1 > 0) {
          await _chatService.updateUnreadCount(
              chat.chatId, currentUserId, true);
        }
      } else if (currentUserId == chat.user2Id) {
        if (chat.unreadCountUser2 > 0) {
          await _chatService.updateUnreadCount(
              chat.chatId, currentUserId, false);
        }
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChattingPage(
            chatId: chat.chatId,
            name: partnerInfo['name'] as String,
            partnerId: partnerInfo['id'] as int,
          ),
        ),
      ).then((_) {
        _loadChatList();
      });
    } catch (e) {
      // Silently handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: _loadChatList,
        child: isLoading
            ? _buildShimmerLoading()
            : chatList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: chatList.length,
                    itemBuilder: (context, index) {
                      final chat = chatList[index];
                      final partnerInfo = chat.getPartnerInfo(currentUserId);
                      final unreadCount = currentUserId == chat.user1Id
                          ? chat.unreadCountUser1
                          : chat.unreadCountUser2;

                      return ChatListItem(
                        chatItem: ChatItem(
                          chatId: chat.chatId,
                          name: partnerInfo['name'] as String,
                          lastMessage: chat.lastMessageContent,
                          time: _formatDateTime(chat.lastMessageTime),
                          unreadCount: unreadCount,
                          avatarColor:
                              Colors.primaries[index % Colors.primaries.length],
                          onlineStatus: partnerInfo['onlineStatus'] as bool,
                          profilePicture:
                              partnerInfo['profilePicture'] as String?,
                          messageStatus: chat.lastMessageStatus,
                          lastMessageSenderId: chat.lastMessageSenderId,
                        ),
                        primaryPurple: primaryPurple,
                        onTap: () => _handleChatOpen(chat, partnerInfo),
                        currentUserId: currentUserId,
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPurple,
        elevation: 2,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ContactListPage(currentUserId: currentUserId),
            ),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6, // Jumlah item shimmer yang ditampilkan
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar shimmer
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name shimmer
                      Container(
                        width: 120,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      // Message shimmer
                      Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                // Time shimmer
                Container(
                  width: 40,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      // Parse tanggal dari format "11-03-2024 07:43:43"
      List<String> dateAndTime = dateTimeStr.split(' ');
      List<String> dateParts = dateAndTime[0].split('-');
      List<String> timeParts = dateAndTime[1].split(':');

      DateTime messageTime = DateTime(
        int.parse(dateParts[2]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[0]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
      );

      DateTime now = DateTime.now();

      // Bandingkan tanggal tanpa waktu
      bool isToday = messageTime.year == now.year &&
          messageTime.month == now.month &&
          messageTime.day == now.day;

      bool isYesterday = messageTime.year == now.year &&
          messageTime.month == now.month &&
          messageTime.day == now.day - 1;

      if (isToday) {
        // Format jam (HH:mm)
        return "${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}";
      } else if (isYesterday) {
        return "Yesterday";
      } else {
        // Format tanggal (dd/mm/yy)
        return "${dateParts[0]}/${dateParts[1]}/${dateParts[2].substring(2)}";
      }
    } catch (e) {
      print('Error formatting date: $e');
      return dateTimeStr;
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 1,
      backgroundColor: primaryPurple,
      title: const Text(
        'ChatZone',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 26,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 28),
          onPressed: () {
            // Implement search functionality
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
          onSelected: (value) {
            if (value == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ProfilePage(phoneNumber: 'userPhoneNumber'),
                ),
              );
            } else if (value == 'logout') {
              // Implement logout functionality
              _logout(context);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'profile',
              child: Text('Profile'),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        ),
      ],
    );
  }

  void _logout(BuildContext context) async {
    try {
      await AuthService().logout();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RegisterPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Chats Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation by tapping the message button below',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final ChatItem chatItem;
  final Color primaryPurple;
  final VoidCallback onTap;
  final int currentUserId;

  const ChatListItem({
    super.key,
    required this.chatItem,
    required this.primaryPurple,
    required this.onTap,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // Menggunakan onTap callback
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameAndTime(),
                  const SizedBox(height: 4),
                  _buildLastMessage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: chatItem.avatarColor,
          backgroundImage: chatItem.profilePicture != null &&
                  chatItem.profilePicture!.isNotEmpty
              ? NetworkImage(
                  'http://10.0.2.2:3000/media/profile_pictures/${chatItem.profilePicture}')
              : null,
          child: (chatItem.profilePicture == null ||
                  chatItem.profilePicture!.isEmpty)
              ? Text(
                  chatItem.name.isNotEmpty 
                      ? chatItem.name.split(' ').map((word) => word[0].toUpperCase()).join('').substring(0, min<int>(2, chatItem.name.split(' ').length))
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        if (chatItem.onlineStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNameAndTime() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            chatItem.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          chatItem.time,
          style: TextStyle(
            fontSize: 12,
            color: chatItem.unreadCount > 0 ? primaryPurple : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLastMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (currentUserId == chatItem.lastMessageSenderId)
                if (chatItem.messageStatus == 'read')
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.done_all,
                      size: 16,
                      color: primaryPurple,
                    ),
                  )
                else if (chatItem.messageStatus == 'delivered')
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.done_all,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  )
                else if (chatItem.messageStatus == 'sent')
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.done,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
              Expanded(
                child: Text(
                  chatItem.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (chatItem.unreadCount > 0)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryPurple,
              shape: BoxShape.circle,
            ),
            child: Text(
              chatItem.unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

enum MessageStatus { sent, delivered, read }

class ChatItem {
  final int chatId;
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final Color avatarColor;
  final bool onlineStatus;
  final String? profilePicture;
  final bool pinned;
  final String messageStatus;
  final int lastMessageSenderId;

  ChatItem({
    required this.chatId,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    required this.avatarColor,
    this.onlineStatus = false,
    this.profilePicture,
    this.pinned = false,
    required this.messageStatus,
    required this.lastMessageSenderId,
  });
}
