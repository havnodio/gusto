import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../AdminDashboardPage.dart'; // import your admin page
import 'forget_password.dart';
import '../UserHomePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  AnimationController? _controller;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
    _controller!.forward();
    _checkInternetConnectivity();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkInternetConnectivity() async {
    try {
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        if (!mounted) return;
        _showMessage('No internet connection. Please check your network.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('No internet connection. Please check your network.');
    }
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      _showMessage('Email and password are required');
      return;
    }
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Retry logic: attempt up to 3 times
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final response = await http
              .post(
                Uri.parse(
                  'https://flutter-backend-xhrw.onrender.com/api/login',
                ),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'email': email, 'password': password}),
              )
              .timeout(const Duration(seconds: 15)); // Increased timeout
          print(
            'Login attempt $attempt response: ${response.statusCode} - ${response.body}',
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final prefs = await SharedPreferences.getInstance();
            final token = data['token'];
            await prefs.setString('token', token);

            Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
            String role = decodedToken['role'];

            if (!mounted) return;
            if (role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardPage(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserHomePage()),
              );
            }
            return; // stop further retries after success
          } else {
            if (!mounted) return;
            _showMessage(
              'Login failed: ${jsonDecode(response.body)['message'] ?? 'Error ${response.statusCode}'}',
            );
            break; // break retry loop if login failed
          }
        } catch (e) {
          print('Login attempt $attempt error: $e');
          if (attempt == 3) {
            if (!mounted) return;
            _showMessage('Error: Unable to connect to server - $e');
          }
          await Future.delayed(
            const Duration(seconds: 2),
          ); // Delay before retry
        }
      }
    } catch (e) {
      print('Login error: $e');
      if (!mounted) return;
      _showMessage('Error: Unable to connect to server - $e');
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _fadeAnimation == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation!,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText:
                        emailController.text.isNotEmpty &&
                            !emailController.text.contains('@')
                        ? 'Invalid email'
                        : null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) =>
                      setState(() {}), // Update error text dynamically
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator(color: Colors.teal)
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgetPassword(),
                    ),
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
