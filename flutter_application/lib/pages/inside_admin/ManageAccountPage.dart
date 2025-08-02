import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({super.key});

  @override
  State<ManageAccountPage> createState() => _ManageAccountPageState();
}

class _ManageAccountPageState extends State<ManageAccountPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> requests = [];
  bool isLoading = true;
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
    _fetchRequests();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http
          .get(
            Uri.parse(
              'https://flutter-backend-xhrw.onrender.com/api/account-requests',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Fetch account requests response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        setState(() {
          requests = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        _showMessage(
          'Failed to load requests: ${jsonDecode(response.body)['message'] ?? 'Error ${response.statusCode}'}',
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Fetch requests error: $e');
      _showMessage('Error: Unable to connect to server - $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _approveRequest(String id) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http
          .post(
            Uri.parse(
              'https://flutter-backend-xhrw.onrender.com/api/account-requests/$id/approve',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Approve request response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        _showMessage('Request approved', isError: false);
        _fetchRequests();
      } else {
        _showMessage(
          'Failed to approve request: ${jsonDecode(response.body)['message'] ?? 'Error ${response.statusCode}'}',
        );
      }
    } catch (e) {
      print('Approve request error: $e');
      _showMessage('Error: Unable to connect to server - $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _rejectRequest(String id) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http
          .post(
            Uri.parse(
              'https://flutter-backend-xhrw.onrender.com/api/account-requests/$id/reject',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Reject request response: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 200) {
        _showMessage('Request rejected', isError: false);
        _fetchRequests();
      } else {
        _showMessage(
          'Failed to reject request: ${jsonDecode(response.body)['message'] ?? 'Error ${response.statusCode}'}',
        );
      }
    } catch (e) {
      print('Reject request error: $e');
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
    if (_controller == null || _fadeAnimation == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Manage Account Requests',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : FadeTransition(
              opacity: _fadeAnimation!,
              child: requests.isEmpty
                  ? Center(
                      child: Text(
                        'No account requests',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              request['email'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Name: ${request['fullName']}\nStatus: ${request['status']}',
                              style: GoogleFonts.poppins(),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (request['status'] == 'pending')
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed: () =>
                                        _approveRequest(request['_id']),
                                  ),
                                if (request['status'] == 'pending')
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _rejectRequest(request['_id']),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
