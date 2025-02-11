import 'package:flutter/material.dart';
import '../app/register.dart';
import '../pages/profile.dart';
import '../pages/chat.dart';
import '../pages/chatting.dart';
import '../pages/status.dart';
import '../pages/community.dart';
import '../pages/calls.dart';

class AppRoutes {
  static const String register = '/register';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String chatting = '/chatting';
  static const String status = '/status';
  static const String community = '/community';
  static const String calls = '/calls';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case profile:
        final phoneNumber = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => ProfilePage(phoneNumber: phoneNumber));
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatPage());
      case chatting:
        final arguments = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChattingPage(
            name: arguments['name'],
            chatId: arguments['chatId'],
            partnerId: arguments['partnerId'],
          ),
        );
      case status:
        return MaterialPageRoute(builder: (_) => const StatusPage());
      case community:
        return MaterialPageRoute(builder: (_) => const CommunityPage());
      case calls:
        return MaterialPageRoute(builder: (_) => const CallsPage());
      default:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
    }
  }
}
