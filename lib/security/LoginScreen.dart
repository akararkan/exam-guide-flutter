import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import '../global.dart';
import '../student_screens/StudentMainScreen.dart';
import '../teacher_screens/TeacherMainScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Updated image with rounded border at the bottom
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(24)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(24)),
                      child: Image.asset(
                        'assets/images/Logo.png',
                        height: 400, // Increased size of the logo
                        width: 650,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Improved Login text styling
                  Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 32, // Larger font size
                      fontWeight: FontWeight.bold, // Bold text
                      color: Color(0xFF6200EE), // Custom primary color
                      letterSpacing: 1.5, // Spacing between letters
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFD9D9D9)), // Light gray border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF6200EE)), // Focused border color
                      ),
                      filled: true,
                      fillColor: Colors
                          .white, // White background for input fields
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(
                              0xFF6200EE), // Custom primary color
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFD9D9D9)), // Light gray border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF6200EE)), // Focused border color
                      ),
                      filled: true,
                      fillColor: Colors
                          .white, // White background for input fields
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        String email = _emailController.text;
                        String password = _passwordController.text;
                        if (email.isNotEmpty && password.isNotEmpty) {
                          login(email, password); // Call the login method
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter both fields')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        // Custom primary color
                        foregroundColor: Colors.white,
                        // White text color
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      String email = _emailController.text;
                      String password = _passwordController.text;
                      if (email.isNotEmpty && password.isNotEmpty) {
                        login(email, password); // Call the login method
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter both fields')),
                        );
                      }
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF6200EE), // Custom primary color
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

  bool _validateInputs(String email, String password) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }
    return true;
  }

  Future<void> login(String email, String password) async {
    if (!_validateInputs(email, password)) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6200EE)),
          ),
        );
      },
    );

    try {
      final response = await http.post(
        Uri.parse('$api/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timeout. Please check your internet.');
        },
      );

      Navigator.of(context, rootNavigator: true).pop();

      switch (response.statusCode) {
        case 200:
          var data = json.decode(response.body);
          String token = data['token'];

          if (token.isEmpty) {
            _showErrorSnackBar('Authentication failed. Please try again.');
            return;
          }

          Map<String, dynamic> decodedToken;
          try {
            decodedToken = Jwt.parseJwt(token);
            globalUserId = decodedToken['id']; // Save userId globally
          } catch (e) {
            _showErrorSnackBar('Invalid authentication token.');
            return;
          }

          String role = decodedToken['ROLE'] ?? '';
          _navigateBasedOnRole(role);
          break;
        case 401:
          _showErrorSnackBar(
              'Invalid credentials. Please check and try again.');
          break;
        case 500:
          _showErrorSnackBar('Server error. Please try again later.');
          break;
        default:
          _showErrorSnackBar('An unexpected error occurred.');
      }
    } on SocketException {
      _showErrorSnackBar('Network error. Please check your connection.');
    } on TimeoutException {
      _showErrorSnackBar('Connection timed out. Please try again.');
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateBasedOnRole(String role) {
    switch (role) {
      case 'STUDENT':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentMainScreen()),
        );
        break;
      case 'TEACHER':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherMainScreen()),
        );
        break;
      default:
        _showErrorSnackBar('Unauthorized access');
    }
  }
}