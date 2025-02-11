import 'package:flutter/material.dart';
import '../services/contact_service.dart';
import '../pages/chatting.dart';
import '../services/chat_service.dart';
import 'dart:math' show min;
import 'package:shimmer/shimmer.dart';

class ContactListPage extends StatefulWidget {
  final int currentUserId;

  const ContactListPage({super.key, required this.currentUserId});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  final ContactService _contactService = ContactService();
  final Color primaryPurple = const Color(0xFF6200EE);
  List<ContactModel> contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => isLoading = true);
      final List<ContactModel> contactList =
          await _contactService.getContacts(widget.currentUserId);
      setState(() {
        contacts = contactList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: primaryPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select contact',
              style: TextStyle(color: Colors.white, fontSize: 19),
            ),
            Text(
              '${contacts.length} contacts',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search functionality
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              // Handle menu selection
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'invite',
                child: Text('Invite a friend'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadContacts,
        child: isLoading
            ? _buildShimmerLoading()
            : ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return _buildContactItem(contact);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPurple,
        child: const Icon(Icons.person_add),
        onPressed: () {
          // Implement add contact functionality
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 8,
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
                      Container(
                        width: 140,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 200,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactItem(ContactModel contact) {
    return InkWell(
      onTap: () async {
        try {
          if (!mounted) return;

          // Get chat list to check if chat exists
          final ChatService chatService = ChatService();
          final List<ChatModel> chats = await chatService.getChatList();

          // Find existing chat with this contact
          final existingChat = chats.firstWhere(
            (chat) =>
                (chat.user1Id == contact.contactUserId &&
                    chat.user2Id == widget.currentUserId) ||
                (chat.user1Id == widget.currentUserId &&
                    chat.user2Id == contact.contactUserId),
            orElse: () => ChatModel(
              chatId: 0,
              user1Id: 0,
              user1Name: '',
              user1OnlineStatus: false,
              user2Id: 0,
              user2Name: '',
              user2OnlineStatus: false,
              lastMessageContent: '',
              lastMessageTime: '',
              unreadCountUser1: 0,
              unreadCountUser2: 0,
              lastMessageSenderId: 0,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChattingPage(
                chatId: existingChat.chatId, // Will be 0 if chat doesn't exist
                name: contact.username,
                partnerId: contact.contactUserId,
              ),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening chat: $e')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.primaries[
                  contact.username.hashCode % Colors.primaries.length],
              backgroundImage: contact.profilePicture != null &&
                      contact.profilePicture?.isNotEmpty == true
                  ? NetworkImage(
                      'http://10.0.2.2:3000/media/profile_pictures/${contact.profilePicture}')
                  : null,
              child: (contact.profilePicture == null ||
                      contact.profilePicture?.isEmpty == true)
                  ? Text(
                      contact.username
                          .split(' ')
                          .map((word) => word[0].toUpperCase())
                          .join('')
                          .substring(0,
                              min<int>(2, contact.username.split(' ').length)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.info,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
