import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for typography
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
        title: Text('Confirm Delete', style: GoogleFonts.poppins()),
        content: Text(
          'Delete client "$fullName"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
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
        content: Text(message, style: GoogleFonts.poppins()),
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
        title: Text(
          client == null ? 'Add Client' : 'Edit Client',
          style: GoogleFonts.poppins(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: numberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fiscalNumberController,
                decoration: InputDecoration(
                  labelText: 'Fiscal Number *',
                  labelStyle: GoogleFonts.poppins(),
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
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
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
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.teal)),
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
      backgroundColor: Colors.white, // Explicitly set to white as requested
      appBar: AppBar(
        title: Text(
          'Clients',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No clients available',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
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
                  elevation: 4, // Increased for more depth
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Softer corners
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    title: Text(
                      client['fullName'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87, // Better contrast
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fiscal Number: ${client['fiscalNumber']}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        if (client['email'].isNotEmpty)
                          Text(
                            'Email: ${client['email']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        if (client['number'].isNotEmpty)
                          Text(
                            'Phone: ${client['number']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.teal,
                            size: 28,
                          ), // Larger icon
                          onPressed: () => _showAddEditDialog(client: client),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 28,
                          ), // Larger icon
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
