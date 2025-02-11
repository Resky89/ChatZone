import 'package:chatzone/app/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../main.dart';
import 'register2.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+62';
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/background_pattern.png'),
            opacity: 0.1,
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: MyApp.primaryPurple.withOpacity(0.2),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 80,
                      color: MyApp.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        MyApp.primaryPurple,
                        Color(0xFF8B5CF6),
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'ChatZone',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Enter Your Phone Number',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'We\'ll send you a verification code',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildPhoneInput(),
                              const SizedBox(height: 24),
                              _buildRegisterButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: CountryCodePicker(
              onChanged: (CountryCode countryCode) {
                setState(() {
                  _selectedCountryCode = countryCode.dialCode!;
                });
              },
              initialSelection: 'ID',
              favorite: const ['+62', '+1', '+44', '+81', '+86', '+61', '+91'],
              showCountryOnly: false,
              showOnlyCountryWhenClosed: false,
              alignLeft: false,
              searchDecoration: InputDecoration(
                hintText: 'Search country',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              dialogSize: const Size(320, 500),
              flagWidth: 28,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Phone number',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                errorStyle: const TextStyle(height: 0.8),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length < 6) {
                  return 'Phone number is too short';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _registerUser,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: MyApp.primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text('CONTINUE'),
      ),
    );
  }

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = '$_selectedCountryCode${_phoneController.text}';

      try {
        print('Checking phone number: $phoneNumber');
        final response = await _userService.getUserByPhoneNumber(phoneNumber);
        print('API Response: $response');

        if (response['status'] == true && response['data'] != null) {
          final userData = response['data'];
          final userId = userData['user_id'] as int;

          print(
              'Attempting to save user data - Phone: $phoneNumber, ID: $userId');

          try {
            final authResult =
                await AuthService().saveUserPhone(phoneNumber, userId);

            if (authResult['success'] == true && mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardPage(
                    phoneNumber: authResult['phone'],
                    userId: userId,
                  ),
                ),
                (route) => false,
              );
            }
          } catch (authError) {
            print('Error saving user data: $authError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save user data: $authError')),
              );
            }
          }
        } else {
          print('User not found, proceeding to Register2');
          _proceedToRegister2(phoneNumber);
        }
      } catch (e) {
        print('Error during registration: $e');
        _proceedToRegister2(phoneNumber);
      }
    }
  }

  void _proceedToRegister2(String phoneNumber) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Register2Page(phoneNumber: phoneNumber),
        ),
      );
    }
  }
}
