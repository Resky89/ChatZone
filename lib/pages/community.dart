import 'package:flutter/material.dart';
import 'profile.dart'; // Pastikan untuk mengimpor ProfilePage
import '../app/register.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import 'package:shimmer/shimmer.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final Color primaryPurple = const Color(0xFF6200EE);
  final Color lightPurple = const Color(0xFFBB86FC);
  late final CommunityService _communityService;
  List<Community> _communities = [];
  bool _isLoading = true;
  late final AuthService _authService;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _communityService = CommunityService();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final userId = await _authService.getCurrentUserId();
    setState(() {
      _userId = userId;
    });
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    if (_userId == null) {
      print('No user ID available');
      return;
    }

    try {
      setState(() => _isLoading = true);
      final communities = await _communityService.getUserCommunities(_userId!);
      setState(() {
        _communities = communities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading communities: $e');
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load communities: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Communities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProfilePage(phoneNumber: 'userPhoneNumber'),
                  ),
                );
              } else if (value == 'logout') {
                await _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCommunities,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildNewCommunityTile(),
              Divider(height: 8, thickness: 8, color: Colors.grey[200]),
              _isLoading ? _buildShimmerLoading() : _buildCommunityList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPurple,
        child: const Icon(Icons.group_add, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stay connected with your communities',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Communities bring members together in topic-based groups, and make it easy to get admin announcements.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewCommunityTile() {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primaryPurple.withOpacity(0.1),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.groups,
            color: primaryPurple,
            size: 30,
          ),
        ),
        title: const Text(
          'New community',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: _showCreateCommunityDialog,
      ),
    );
  }

  Widget _buildCommunityList() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }
    return Column(
      children: List.generate(
        _communities.length,
        (index) => _buildCommunityItem(index),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        // Header shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 24,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        // Community items shimmer
        ...List.generate(3, (index) => _buildShimmerCommunityItem()),
      ],
    );
  }

  Widget _buildShimmerCommunityItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            // Community icon shimmer
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
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
  }

  Widget _buildCommunityItem(int index) {
    final community = _communities[index];
    final communityImageUrl = community.communityImageUrl != null
        ? 'http://10.0.2.2:3000/media/community_images/${community.communityImageUrl}'
        : null;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: lightPurple.withOpacity(0.2),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: communityImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      communityImageUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      community.communityName[0].toUpperCase(),
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  community.communityName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      // Handle edit community
                      break;
                    case 'invite':
                      // Handle invite members
                      break;
                    case 'leave':
                      _showLeaveDialog(index);
                      break;
                    case 'delete':
                      _showDeleteDialog(index);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit Community'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'invite',
                    child: Row(
                      children: [
                        Icon(Icons.person_add, size: 20),
                        SizedBox(width: 8),
                        Text('Invite Members'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, size: 20),
                        SizedBox(width: 8),
                        Text('Leave Community'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Community',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Text(
            '${community.groups.length} groups • ${community.totalMembers} members',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          children: [
            _buildAnnouncementGroup(),
            ..._buildGroupsForCommunity(community),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupsForCommunity(Community community) {
    return community.groups.map((group) {
      final groupImageUrl = group.groupImageUrl != null
          ? 'https://2ef5-140-213-128-159.ngrok-free.app/media/group_images/${group.groupImageUrl}'
          : null;

      return Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightPurple.withOpacity(0.2),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: groupImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          groupImageUrl,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.group,
                        color: primaryPurple,
                        size: 24,
                      ),
              ),
              title: Text(
                group.groupName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Created ${group.createdAt}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
            if (group != community.groups.last)
              const Divider(height: 1, indent: 72),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _showLeaveDialog(int index) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Community'),
          content:
              Text('Are you sure you want to leave Community ${index + 1}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Leave', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Handle leave community
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(int index) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Community'),
          content: Text(
              'Are you sure you want to delete Community ${index + 1}? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Handle delete community
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnnouncementGroup() {
    return Container(
      color: Colors.grey[50],
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryPurple.withOpacity(0.1),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.campaign,
            color: primaryPurple,
            size: 24,
          ),
        ),
        title: const Text(
          'Announcements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Only admins can send messages',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Text(
              '12:30 PM',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primaryPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '2',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateCommunityDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Community'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Community Name',
                    hintText: 'Enter community name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter community description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Create', style: TextStyle(color: primaryPurple)),
              onPressed: () {
                // Validasi input
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter community name')),
                  );
                  return;
                }
                // Handle create community
                _createCommunity(
                  nameController.text.trim(),
                  descriptionController.text.trim(),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCommunity(String name, String description) async {
    try {
      // TODO: Implement API call to create community
      // Contoh:
      // await communityService.createCommunity(name, description);

      setState(() {
        // Refresh community list
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create community: ${e.toString()}')),
      );
    }
  }
}
