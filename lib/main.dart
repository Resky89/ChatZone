import 'package:flutter/material.dart';
import 'app/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static const Color primaryPurple = Color(0xFF6200EE);
  static const Color lightPurple = Color(0xFFBB86FC);

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatZone',
      theme: ThemeData(
        primaryColor: primaryPurple,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: primaryPurple,
          secondary: lightPurple,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
