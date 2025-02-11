import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'profile.dart';
import '../services/auth_service.dart';
import '../app/register.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' show min;
import 'package:shimmer/shimmer.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  _CallsPageState createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  final AuthService _authService = AuthService();
  bool isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedCalls = {};
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _callLogs = [];
  final Color primaryPurple = const Color(0xFF6200EE);
  final Color lightPurple = const Color(0xFFBB86FC);
  final Color backgroundColor = const Color(0xFFF8F9FE);
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchCallLogs();
    // Set timer untuk refresh data setiap 5 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isSelectionMode) {
        // Hanya refresh jika tidak dalam mode selection
        _fetchCallLogs(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCallLogs({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() => isLoading = true);
      }

      final userId = await _authService.getCurrentUserId();
      final calls = await _callService.getCallLogsByUserId(userId.toString());

      if (mounted) {
        setState(() {
          _callLogs = calls;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading calls: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: _isSelectionMode
            ? AppBar(
                elevation: 0,
                backgroundColor: primaryPurple,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedCalls.clear();
                    });
                  },
                ),
                title: Text(
                  '${_selectedCalls.length} selected',
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelectedCalls,
                  ),
                ],
              )
            : AppBar(
                elevation: 0,
                backgroundColor: primaryPurple,
                toolbarHeight: 70,
                title: const Text(
                  'Calls',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    letterSpacing: 0.5,
                  ),
                ),
                actions: [
                  IconButton(
                    icon:
                        const Icon(Icons.search, color: Colors.white, size: 26),
                    onPressed: () {},
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: Colors.white, size: 26),
                    onSelected: (value) async {
                      if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(
                                phoneNumber: 'userPhoneNumber'),
                          ),
                        );
                      } else if (value == 'logout') {
                        await _logout();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
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
                bottom: const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt, size: 20),
                          SizedBox(width: 8),
                          Text('All'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_missed, size: 20),
                          SizedBox(width: 8),
                          Text('Missed'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        body: TabBarView(
          children: [
            _buildCallList(false),
            _buildCallList(true),
          ],
        ),
        floatingActionButton: _buildExpandableFloatingActionButton(),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
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

  Future<void> _deleteSelectedCalls() async {
    try {
      if (_selectedCalls.isEmpty) return;

      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete ${_selectedCalls.length} call(s)?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('DELETE'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      setState(() => isLoading = true);

      final List<String> validCallIds = _selectedCalls
          .where((id) => id.isNotEmpty)
          .toList();
      final Map<String, bool> results =
          await _callService.deleteMultipleCallLogs(validCallIds);

      setState(() {
        _isSelectionMode = false;
        _selectedCalls.clear();
      });

      await _fetchCallLogs(showLoading: false);

      if (!mounted) return;

      final successCount = results.values.where((success) => success).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted $successCount call(s)'),
          backgroundColor:
              successCount == validCallIds.length ? null : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete calls: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildExpandableFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton.small(
              heroTag: 'fab_video_call',
              backgroundColor: lightPurple,
              elevation: 4,
              onPressed: () {},
              child: const Icon(Icons.videocam, color: Colors.white),
            ),
          ),
        ),
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton.small(
              heroTag: 'fab_voice_call',
              backgroundColor: lightPurple,
              elevation: 4,
              onPressed: () {},
              child: const Icon(Icons.call, color: Colors.white),
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'fab_main',
          backgroundColor: primaryPurple,
          elevation: 4,
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            });
          },
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isExpanded ? Icons.close : Icons.add_call,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallList(bool missedOnly) {
    return RefreshIndicator(
      onRefresh: () => _fetchCallLogs(showLoading: false),
      child: isLoading
          ? _buildShimmerLoading()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _callLogs.length,
              itemBuilder: (context, index) {
                final call = _callLogs[index];
                final bool isMissed = call['Call Status'] == 'missed';
                final String callId = call['id'].toString();
                final bool isSelected = _selectedCalls.contains(callId);

                return Column(
                  children: [
                    ListTile(
                      leading: Stack(
                        children: [
                          _buildAvatar(call),
                          if (_isSelectionMode)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryPurple.withOpacity(0.7)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        call['Contact Name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          _buildCallDirectionIcon(
                            call['Call Direction'] == 'Incoming',
                            isMissed,
                            call['Call Type'] == 'video',
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(call['Call Timestamp']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      trailing: _isSelectionMode
                          ? null
                          : IconButton(
                              icon: Icon(
                                call['Call Type'] == 'video'
                                    ? Icons.videocam
                                    : Icons.call,
                                color: primaryPurple,
                              ),
                              onPressed: () {
                                // Handle call action
                              },
                            ),
                      onLongPress: () {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedCalls.add(callId);
                        });
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            if (isSelected) {
                              _selectedCalls.remove(callId);
                              if (_selectedCalls.isEmpty) {
                                _isSelectionMode = false;
                              }
                            } else {
                              _selectedCalls.add(callId);
                            }
                          });
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 72, right: 16),
                      child: Divider(height: 1, color: Colors.grey[300]),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Avatar shimmer
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 4),
                      // Time and status shimmer
                      Container(
                        width: 80,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                // Call icon shimmer
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Map<String, dynamic> call) {
    final String? profilePicture = call['Profile Picture'];
    final String contactName = call['Contact Name'] ?? 'Unknown';
    final int contactId = call['Contact Id'] ?? 0;

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.primaries[contactId % Colors.primaries.length],
      backgroundImage: profilePicture != null && profilePicture.isNotEmpty
          ? NetworkImage('http://10.0.2.2:3000/media/profile_pictures/$profilePicture')
          : null,
      child: (profilePicture == null || profilePicture.isEmpty)
          ? Text(
              contactName.split(' ').map((word) => word[0].toUpperCase()).join('').substring(0, min(2, contactName.split(' ').length)),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  Widget _buildCallDirectionIcon(bool isIncoming, bool isMissed, bool isVideo) {
    IconData icon;
    Color iconColor;

    if (isMissed) {
      icon = Icons.call_missed;
      iconColor = Colors.red;
    } else if (isIncoming) {
      icon = Icons.call_received;
      iconColor = Colors.green;
    } else {
      icon = Icons.call_made;
      iconColor = Colors.green;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        if (isVideo)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.videocam, size: 14, color: Colors.grey[600]),
          ),
      ],
    );
  }

  String _formatDateTime(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final DateTime yesterday = now.subtract(const Duration(days: 1));

      // Format untuk jam
      final timeFormat = DateFormat('HH:mm');
      final String time = timeFormat.format(dateTime);

      if (dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day) {
        return 'Today, $time';
      } else if (dateTime.year == yesterday.year &&
          dateTime.month == yesterday.month &&
          dateTime.day == yesterday.day) {
        return 'Yesterday, $time';
      } else {
        // Ubah format tanggal menjadi dd MMM
        final dateFormat = DateFormat('dd MMM');
        return '${dateFormat.format(dateTime)}, $time';
      }
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_missed,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Calls Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you make or receive calls,\nthey will appear here',
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
