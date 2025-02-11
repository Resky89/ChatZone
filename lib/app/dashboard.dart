import 'package:flutter/material.dart';
import '../pages/chat.dart';
import '../pages/status.dart';
import '../pages/community.dart';
import '../pages/calls.dart';
import '../main.dart';

class DashboardPage extends StatefulWidget {
  final String phoneNumber;
  final int userId;

  const DashboardPage({
    super.key, 
    required this.phoneNumber, 
    required this.userId,
  });

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ChatPage(),
      const StatusPage(),
      const CommunityPage(),
      const CallsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: MyApp.primaryPurple,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          elevation: 0,
          backgroundColor: Colors.white,
          items: [
            _buildNavItem(Icons.message, Icons.message_rounded, 'Chats'),
            _buildNavItem(Icons.circle_outlined, Icons.circle_outlined, 'Updates'),
            _buildNavItem(Icons.groups, Icons.groups_rounded, 'Communities'),
            _buildNavItem(Icons.call, Icons.call_rounded, 'Calls'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MyApp.lightPurple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(activeIcon),
      ),
      label: label,
    );
  }
}
