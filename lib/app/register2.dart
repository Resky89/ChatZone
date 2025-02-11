import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dashboard.dart';
import '../main.dart';
import '../services/user_service.dart'; // Import UserService
import 'package:path/path.dart' as path;
import '../services/auth_service.dart';
import 'register.dart';

class Register2Page extends StatefulWidget {
  final String phoneNumber;

  const Register2Page({super.key, required this.phoneNumber});

  @override
  _Register2PageState createState() => _Register2PageState();
}

class _Register2PageState extends State<Register2Page> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String? _profileImagePath;
  final UserService _userService = UserService(); // Initialize UserService
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkUserExists();
  }

  void _checkUserExists() async {
    try {
      final user = await _userService.getUserByPhoneNumber(widget.phoneNumber);
      if (user.isNotEmpty) {
        // User exists, populate fields
        _usernameController.text = user['username'];
        // Load profile picture if available
        setState(() {
          _profileImagePath = user['profile_picture'];
        });
      }
    } catch (e) {
      // Handle error
      print('Error loading user data: $e');
      // Stay on registration page to complete profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterPage(),
            ),
          ),
        ),
        title: const Text(
          'Profile info',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: MyApp.primaryPurple,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Please provide your name and an optional profile photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 64,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _profileImagePath != null
                                  ? FileImage(File(_profileImagePath!))
                                  : null,
                              child: _profileImagePath == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 64,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: MyApp.primaryPurple,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(8),
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
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Your name',
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: MyApp.primaryPurple),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyApp.primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'DONE',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Validate file extension
        final extension = path.extension(pickedFile.path).toLowerCase();
        if (['.jpg', '.jpeg', '.png'].contains(extension)) {
          setState(() {
            _profileImagePath = pickedFile.path;
          });
          print('Image picked: ${pickedFile.path}');
          print('Image extension: $extension');
        } else {
          throw Exception('Please select a JPG or PNG image');
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeRegistration() async {
    if (_formKey.currentState!.validate()) {
        setState(() {
            _isLoading = true;
        });

        try {
            // Validate profile picture if exists
            if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
                final File imageFile = File(_profileImagePath!);
                if (!await imageFile.exists()) {
                    throw Exception('Profile picture file does not exist');
                }
                
                final extension = path.extension(_profileImagePath!).toLowerCase();
                if (!['.jpg', '.jpeg', '.png'].contains(extension)) {
                    throw Exception('Invalid image format. Please use JPG, JPEG or PNG');
                }
            }

            // Create user and get the response
            final userData = await _userService.createUser(
                widget.phoneNumber,
                _usernameController.text,
                _profileImagePath ?? '',
            );

            // Save user data to SharedPreferences
            final authService = AuthService();
            await authService.saveUserPhone(widget.phoneNumber, userData['user_id']);

            if (!mounted) return;

            // Navigate to Dashboard with both phone number and user ID
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => DashboardPage(
                        phoneNumber: widget.phoneNumber,
                        userId: userData['user_id'],
                    ),
                ),
                (route) => false,
            );
        } catch (e) {
            if (!mounted) return;
            
            setState(() {
                _isLoading = false;
            });

            print('Registration error: $e');
        }
    }
  }
}
