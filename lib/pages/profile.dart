import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final String phoneNumber;

  const ProfilePage({super.key, required this.phoneNumber});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color primaryPurple = const Color(0xFF6200EE);
  final Color lightPurple = const Color(0xFFBB86FC);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  String name = 'Unknown';
  String info = 'No info available';
  String profilePicturePath = '';
  bool isLoading = true;
  late int userId;
  String phoneNumber = '';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  Future<void> _fetchCurrentUserData() async {
    try {
      setState(() => isLoading = true);

      // Get current user ID from AuthService
      final currentUserId = await _authService.getCurrentUserId();

      final userService = UserService();
      final userData = await userService.getUserById(currentUserId);

      if (userData['data'] != null) {
        final user = userData['data'];
        setState(() {
          userId = user['user_id'] ?? 0;
          name = user['username'] ?? 'Unknown';
          phoneNumber = user['phone_number'] ?? '';
          info = user['info'] ?? 'Hey there! I am using ChatZone!';
          profilePicturePath = user['profile_picture'] ?? '';
          isLoading = false;
        });
      } else {
        throw Exception('No user data found');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
        // Set default values if fetch fails
        name = 'Unknown';
        info = 'Hey there! I am using ChatZone!';
      });
    }
  }

  Future<void> _updateUsername(String newName) async {
    try {
      final userService = UserService();
      await userService.updateUserWithImage(
        userId.toString(),
        {'username': newName}, // Hanya kirim field yang diupdate
      );
      setState(() => name = newName);
    } catch (e) {
      print('Error updating username: $e');
    }
  }

  Future<void> _updateInfo(String newInfo) async {
    try {
      final userService = UserService();
      await userService.updateUserWithImage(
        userId.toString(),
        {'info': newInfo}, // Hanya kirim field yang diupdate
      );
      setState(() => info = newInfo);
    } catch (e) {
      print('Error updating info: $e');
    }
  }

  Future<void> _updateProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final userService = UserService();
        await userService.updateUserWithImage(
            userId.toString(), {}, // Tidak ada field yang diupdate
            imageFile: File(image.path));
        await _fetchCurrentUserData(); // Refresh data setelah update
      }
    } catch (e) {
      print('Error updating profile picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            _buildNameSection(),
                            const Divider(height: 1),
                            _buildInfoSection(),
                            const Divider(height: 1),
                            _buildPhoneSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: primaryPurple,
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        background: Container(
          color: primaryPurple,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _updateProfilePicture,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profilePicturePath.isNotEmpty
                            ? NetworkImage(
                                'http://10.0.2.2:3000/media/profile_pictures/$profilePicturePath')
                            : null,
                        child: profilePicturePath.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    );
  }

  Widget _buildNameSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nama',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: primaryPurple, size: 20),
                onPressed: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => _buildEditDialog('Edit Name', name),
                  );
                  if (result != null) {
                    await _updateUsername(result);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This is not your username or pin. This name will be visible to your contacts.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Info',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: primaryPurple, size: 20),
                onPressed: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => _buildEditDialog('Edit Info', info),
                  );
                  if (result != null) {
                    await _updateInfo(result);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            info,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone, color: primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Phone',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            phoneNumber,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditDialog(String title, String initialValue) {
    final controller = TextEditingController(text: initialValue);
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
