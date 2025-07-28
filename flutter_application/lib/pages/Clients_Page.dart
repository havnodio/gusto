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
  final String apiUrl = 'https://flutter-backend-xhrw.onrender.com/api/clients';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      print('No JWT token found in shared_preferences');
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
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
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

  Future<void> _addClient(
    String fullName,
    String? number,
    String? email,
    String fiscalNumber,
  ) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = {'fullName': fullName, 'fiscalNumber': fiscalNumber};
      if (number != null && number.isNotEmpty) body['number'] = number;
      if (email != null && email.isNotEmpty) body['email'] = email;

      print('Adding client with body: $body'); // Debug
      print('Headers: $headers'); // Debug

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 201) {
        await _fetchClients();
        _showError('Client ajouté avec succès', isError: false);
      } else {
        _showError(
          'Error adding client: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _showError('Error adding client: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editClient(
    String id,
    String fullName,
    String? number,
    String? email,
    String fiscalNumber,
  ) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = {'fullName': fullName, 'fiscalNumber': fiscalNumber};
      if (number != null && number.isNotEmpty) body['number'] = number;
      if (email != null && email.isNotEmpty) body['email'] = email;

      print('Editing client with body: $body'); // Debug
      final response = await http.put(
        Uri.parse('$apiUrl/$id'),
        headers: headers,
        body: jsonEncode(body),
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
        content: Text('Are you sure you want to delete "$fullName"?'),
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
        Uri.parse('$apiUrl/$id'),
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

  void _showAddClientDialog() {
    final fullNameController = TextEditingController();
    final numberController = TextEditingController();
    final emailController = TextEditingController();
    final fiscalNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Add New Client',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Number (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fiscalNumberController,
                decoration: InputDecoration(
                  labelText: 'Fiscal Number *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final fullName = fullNameController.text.trim();
              final number = numberController.text.trim();
              final email = emailController.text.trim();
              final fiscalNumber = fiscalNumberController.text.trim();

              if (fullName.isEmpty || fiscalNumber.isEmpty) {
                _showError('Full Name and Fiscal Number are required');
                return;
              }

              await _addClient(fullName, number, email, fiscalNumber);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(int index) {
    final client = clients[index];
    final fullNameController = TextEditingController(text: client['fullName']);
    final numberController = TextEditingController(text: client['number']);
    final emailController = TextEditingController(text: client['email']);
    final fiscalNumberController = TextEditingController(
      text: client['fiscalNumber'],
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Edit Client',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Number (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fiscalNumberController,
                decoration: InputDecoration(
                  labelText: 'Fiscal Number *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final fullName = fullNameController.text.trim();
              final number = numberController.text.trim();
              final email = emailController.text.trim();
              final fiscalNumber = fiscalNumberController.text.trim();

              if (fullName.isEmpty || fiscalNumber.isEmpty) {
                _showError('Full Name and Fiscal Number are required');
                return;
              }

              await _editClient(
                client['_id'],
                fullName,
                number,
                email,
                fiscalNumber,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    _fetchClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clients Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
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
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            )
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
                      client['fullName'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((client['number'] ?? '').isNotEmpty)
                          Text('Number: ${client['number']}'),
                        if ((client['email'] ?? '').isNotEmpty)
                          Text('Email: ${client['email']}'),
                        Text('Fiscal Number: ${client['fiscalNumber']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () => _showEditClientDialog(index),
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
        onPressed: _showAddClientDialog,
        backgroundColor: Colors.teal,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
