import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String stage = 'email'; // 'email', 'code', or 'password'
  String? currentEmail;
  AnimationController? _controller;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
    _controller!.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Please enter a valid email');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse(
              'https://flutter-backend-xhrw.onrender.com/api/users/reset-password-request',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );
      print('Reset request: {"email": "$email"}');
      print('Reset response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          currentEmail = email;
          stage = 'code';
          emailController.clear();
          _controller!.reset();
          _controller!.forward();
        });
        _showMessage('Code sent to $email', isError: false);
      } else {
        final error =
            jsonDecode(response.body)['message'] ??
            'Error ${response.statusCode}';
        _showMessage('Failed to send code: $error');
      }
    } catch (e) {
      print('Send code error: $e');
      _showMessage('Error: Unable to connect to server - $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = codeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      _showMessage('Please enter a valid 6-digit code');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse(
              'https://flutter-backend-xhrw.onrender.com/api/users/verify-reset-code',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': currentEmail, 'code': code}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );
      print('Verify code request: {"email": "$currentEmail", "code": "$code"}');
      print('Verify code response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          stage = 'password';
          codeController.clear();
          _controller!.reset();
          _controller!.forward();
        });
        _showMessage('Code verified', isError: false);
      } else {
        final error =
            jsonDecode(response.body)['message'] ??
            'Error ${response.statusCode}';
        _showMessage('Failed to verify code: $error');
      }
    } catch (e) {
      print('Verify code error: $e');
      _showMessage('Error: Unable to connect to server - $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    if (password.isEmpty || password.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse(
              'https://flutter-backend-xhrw.onrender.com/api/users/reset-password',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': currentEmail, 'newPassword': password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );
      print(
        'Reset password request: {"email": "$currentEmail", "newPassword": "[hidden]"}',
      );
      print(
        'Reset password response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        _showMessage('Password reset successfully', isError: false);
        Navigator.pop(context);
      } else {
        final error =
            jsonDecode(response.body)['message'] ??
            'Error ${response.statusCode}';
        _showMessage('Failed to reset password: $error');
      }
    } catch (e) {
      print('Reset password error: $e');
      _showMessage('Error: Unable to connect to server - $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null ||
        _fadeAnimation == null ||
        _slideAnimation == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Forgot Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FadeTransition(
            opacity: _fadeAnimation!,
            child: SlideTransition(
              position: _slideAnimation!,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stage == 'email'
                        ? 'Password Recovery'
                        : stage == 'code'
                        ? 'Enter Code'
                        : 'Reset Password',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (stage == 'email') ...[
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Enter your email',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.teal)
                        : ElevatedButton(
                            onPressed: _sendResetCode,
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
                              'Send Code',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ],
                  if (stage == 'code') ...[
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: 'Enter 6-digit code',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.teal)
                        : ElevatedButton(
                            onPressed: _verifyCode,
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
                              'Verify Code',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ],
                  if (stage == 'password') ...[
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.teal)
                        : ElevatedButton(
                            onPressed: _resetPassword,
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
                              'Reset Password',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
