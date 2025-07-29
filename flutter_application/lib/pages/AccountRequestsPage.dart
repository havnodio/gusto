import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/pages/AdminHomePage.dart';

class AccountRequestsPage extends StatefulWidget {
  const AccountRequestsPage({super.key});

  @override
  State<AccountRequestsPage> createState() => _AccountRequestsPageState();
}

class _AccountRequestsPageState extends State<AccountRequestsPage> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = false;
  final String apiUrl =
      'https://flutter-backend-xhrw.onrender.com/api/account-requests';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      print('No JWT token found');
      throw Exception('No JWT token found');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchRequests() async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          requests = data
              .map(
                (item) => {
                  '_id': item['_id'],
                  'name': item['name'],
                  'surname': item['surname'],
                  'email': item['email'],
                  'status': item['status'],
                },
              )
              .toList();
        });
      } else {
        _showError('Error fetching requests: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching requests: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _approveRequest(String id, String name, String email) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: Text('Approve account for "$name" ($email)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$apiUrl/$id/approve'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        await _fetchRequests();
        _showError('Compte approuvé avec succès', isError: false);
      } else {
        _showError('Error approving request: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error approving request: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _rejectRequest(String id, String name, String email) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: Text('Reject account for "$name" ($email)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$apiUrl/$id/reject'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        await _fetchRequests();
        _showError('Demande rejetée avec succès', isError: false);
      } else {
        _showError('Error rejecting request: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error rejecting request: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomePage()),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : requests.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No account requests',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      '${request['name']} ${request['surname']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${request['email']}'),
                        Text('Status: ${request['status']}'),
                      ],
                    ),
                    trailing: request['status'] == 'pending'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: () => _approveRequest(
                                  request['_id'],
                                  '${request['name']} ${request['surname']}',
                                  request['email'],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => _rejectRequest(
                                  request['_id'],
                                  '${request['name']} ${request['surname']}',
                                  request['email'],
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
