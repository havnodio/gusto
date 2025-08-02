import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  _ClientsPageState createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage>
    with TickerProviderStateMixin {
  List<dynamic> _clients = [];
  List<dynamic> _filteredClients = [];
  String apiUrl = 'https://flutter-backend-xhrw.onrender.com/api/clients';
  bool _isLoading = false;

  TextEditingController fullNameController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController fiscalNumberController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  String? editingClientId;
  AnimationController? _fabAnimationController;
  Animation<double>? _fabAnimation;

  @override
  void initState() {
    super.initState();
    fetchClients();

    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fabAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _fabAnimationController?.dispose();
    searchController.dispose();
    fullNameController.dispose();
    numberController.dispose();
    emailController.dispose();
    fiscalNumberController.dispose();
    super.dispose();
  }

  void _filterClients() {
    final query = searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _clients.where((client) {
        final name = (client['fullName'] ?? '').toLowerCase();
        final email = (client['email'] ?? '').toLowerCase();
        final fiscalNumber = (client['fiscalNumber'] ?? '').toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            fiscalNumber.contains(query);
      }).toList();
    });
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchClients() async {
    setState(() => _isLoading = true);

    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _clients = json.decode(response.body);
          _filteredClients = _clients;
        });
      } else {
        _showErrorSnackBar('Error fetching clients: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Network error: Please check your connection');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> addOrUpdateClient() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'fullName': fullNameController.text.trim(),
        'number': numberController.text.trim(),
        'email': emailController.text.trim(),
        'fiscalNumber': fiscalNumberController.text.trim(),
      });

      final uri = editingClientId == null
          ? Uri.parse(apiUrl)
          : Uri.parse('$apiUrl/$editingClientId');

      final response = editingClientId == null
          ? await http.post(uri, headers: headers, body: body)
          : await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchClients();
        clearForm();
        Navigator.of(context).pop();
        _showSuccessSnackBar(
          editingClientId == null
              ? 'Client added successfully!'
              : 'Client updated successfully!',
        );
      } else {
        _showErrorSnackBar('Error saving client: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Network error: Please check your connection');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (fullNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a full name');
      return false;
    }
    if (emailController.text.trim().isNotEmpty &&
        !_isValidEmail(emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }
    if (fiscalNumberController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a fiscal number');
      return false;
    }
    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void clearForm() {
    fullNameController.clear();
    numberController.clear();
    emailController.clear();
    fiscalNumberController.clear();
    editingClientId = null;
  }

  void populateForm(client) {
    setState(() {
      fullNameController.text = client['fullName'] ?? '';
      numberController.text = client['number'] ?? '';
      emailController.text = client['email'] ?? '';
      fiscalNumberController.text = client['fiscalNumber'] ?? '';
      editingClientId = client['_id'];
    });
  }

  Future<void> deleteClient(String id, String clientName) async {
    final confirmed = await _showDeleteConfirmation(clientName);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$apiUrl/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await fetchClients();
        _showSuccessSnackBar('Client deleted successfully!');
      } else {
        _showErrorSnackBar('Error deleting client: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Network error: Please check your connection');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showDeleteConfirmation(String clientName) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Delete Client'),
                ],
              ),
              content: Text(
                'Are you sure you want to delete "$clientName"? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showClientForm([dynamic client]) {
    if (client != null) {
      populateForm(client);
    }

    _fabAnimationController?.forward();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          editingClientId == null
                              ? Icons.person_add
                              : Icons.edit,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          editingClientId == null
                              ? 'Add New Client'
                              : 'Edit Client',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildFormField(
                              controller: fullNameController,
                              label: 'Full Name',
                              icon: Icons.person,
                              required: true,
                            ),
                            SizedBox(height: 16),
                            _buildFormField(
                              controller: numberController,
                              label: 'Phone Number',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: 16),
                            _buildFormField(
                              controller: emailController,
                              label: 'Email',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: 16),
                            _buildFormField(
                              controller: fiscalNumberController,
                              label: 'Fiscal Number',
                              icon: Icons.receipt_long,
                              required: true,
                            ),
                            SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      clearForm();
                                      Navigator.of(context).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('Cancel'),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : addOrUpdateClient,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            editingClientId == null
                                                ? 'Add Client'
                                                : 'Update Client',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      _fabAnimationController?.reverse();
      clearForm();
    });
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search clients...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    searchController.clear();
                    _filterClients();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildClientCard(dynamic client, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showClientDetails(client),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      child: Text(
                        _getInitials(client['fullName'] ?? ''),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client['fullName'] ?? 'No Name',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                client['fiscalNumber'] ?? 'No fiscal number',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showClientForm(client);
                        } else if (value == 'delete') {
                          deleteClient(
                            client['_id'],
                            client['fullName'] ?? 'Unknown',
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (client['email'] != null && client['email'].isNotEmpty) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.email, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          client['email'],
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (client['number'] != null &&
                    client['number'].isNotEmpty) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        client['number'],
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClientDetails(dynamic client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                _getInitials(client['fullName'] ?? ''),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                client['fullName'] ?? 'No Name',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.receipt_long),
              title: Text('Fiscal Number'),
              subtitle: Text(client['fiscalNumber'] ?? 'N/A'),
            ),
            if (client['email'] != null && client['email'].isNotEmpty)
              ListTile(
                leading: Icon(Icons.email),
                title: Text('Email'),
                subtitle: Text(client['email']),
              ),
            if (client['number'] != null && client['number'].isNotEmpty)
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Phone Number'),
                subtitle: Text(client['number']),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clients'), centerTitle: true),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                ? Center(child: Text('No clients found'))
                : RefreshIndicator(
                    onRefresh: fetchClients,
                    child: ListView.builder(
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, index) =>
                          _buildClientCard(_filteredClients[index], index),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClientForm(),
        tooltip: 'Add Client',
        child: Icon(Icons.add),
      ),
    );
  }
}
