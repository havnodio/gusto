import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/pages/AdminHomePage.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  List<Map<String, dynamic>> clients = [];
  bool isLoading = false;
  final String apiUrl = 'https://flutter-backend-xhrw.onrender.com';

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

  Future<void> _fetchClients() async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$apiUrl/api/clients'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          clients = data
              .map(
                (item) => {
                  '_id': item['_id'],
                  'fullName': item['fullName'],
                  'number': item['number'] ?? '',
                  'email': item['email'] ?? '',
                  'fiscalNumber': item['fiscalNumber'],
                },
              )
              .toList();
        });
      } else {
        _showError('Error fetching clients: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching clients: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addClient(Map<String, dynamic> clientData) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = jsonEncode(clientData);
      final response = await http.post(
        Uri.parse('$apiUrl/api/clients'),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 201) {
        await _fetchClients();
        _showError('Client ajouté avec succès', isError: false);
      } else {
        _showError('Error adding client: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error adding client: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editClient(String id, Map<String, dynamic> clientData) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = jsonEncode(clientData);
      final response = await http.put(
        Uri.parse('$apiUrl/api/clients/$id'),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        await _fetchClients();
        _showError('Client modifié avec succès', isError: false);
      } else {
        _showError('Error editing client: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error editing client: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteClient(String id, String fullName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete client "$fullName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$apiUrl/api/clients/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        await _fetchClients();
        _showError('Client supprimé avec succès', isError: false);
      } else {
        _showError('Error deleting client: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error deleting client: $e');
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

  Future<void> _showAddEditDialog({Map<String, dynamic>? client}) async {
    final fullNameController = TextEditingController(text: client?['fullName']);
    final numberController = TextEditingController(text: client?['number']);
    final emailController = TextEditingController(text: client?['email']);
    final fiscalNumberController = TextEditingController(
      text: client?['fiscalNumber'],
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? 'Add Client' : 'Edit Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name *'),
              ),
              TextFormField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: fiscalNumberController,
                decoration: const InputDecoration(labelText: 'Fiscal Number *'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (fullNameController.text.isEmpty ||
                  fiscalNumberController.text.isEmpty) {
                _showError('Full name and fiscal number are required');
                return;
              }
              Navigator.pop(context);
              final clientData = {
                'fullName': fullNameController.text,
                'number': numberController.text,
                'email': emailController.text,
                'fiscalNumber': fiscalNumberController.text,
              };
              if (client == null) {
                _addClient(clientData);
              } else {
                _editClient(client['_id'], clientData);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clients',
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
          : clients.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No clients available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
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
                      client['fullName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fiscal Number: ${client['fiscalNumber']}'),
                        if (client['email'].isNotEmpty)
                          Text('Email: ${client['email']}'),
                        if (client['number'].isNotEmpty)
                          Text('Phone: ${client['number']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () => _showAddEditDialog(client: client),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteClient(client['_id'], client['fullName']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
