import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application/pages/AdminHomePage.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> products = [];
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

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$apiUrl/api/orders'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          orders = data
              .map(
                (item) => {
                  '_id': item['_id'],
                  'productId': item['productId']['_id'],
                  'productName': item['productId']['name'],
                  'clientId': item['clientId']['_id'],
                  'clientName': item['clientId']['fullName'],
                  'deliveryDate': item['deliveryDate'],
                  'paymentType': item['paymentType'],
                  'status': item['status'],
                },
              )
              .toList();
        });
      } else {
        _showError('Error fetching orders: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching orders: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchProductsAndClients() async {
    try {
      final headers = await _getHeaders();
      final productResponse = await http.get(
        Uri.parse('$apiUrl/api/products'),
        headers: headers,
      );
      final clientResponse = await http.get(
        Uri.parse('$apiUrl/api/clients'),
        headers: headers,
      );
      if (productResponse.statusCode == 200 &&
          clientResponse.statusCode == 200) {
        setState(() {
          products = (jsonDecode(productResponse.body) as List)
              .map((item) => {'_id': item['_id'], 'name': item['name']})
              .toList();
          clients = (jsonDecode(clientResponse.body) as List)
              .map((item) => {'_id': item['_id'], 'fullName': item['fullName']})
              .toList();
        });
      } else {
        _showError('Error fetching products or clients');
      }
    } catch (e) {
      _showError('Error fetching products or clients: $e');
    }
  }

  Future<void> _addOrder(Map<String, dynamic> orderData) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'productId': orderData['productId'],
        'clientId': orderData['clientId'],
        'deliveryDate': orderData['deliveryDate'],
        'paymentType': orderData['paymentType'],
      });
      print('Adding order with body: $body');
      final response = await http.post(
        Uri.parse('$apiUrl/api/orders'),
        headers: headers,
        body: body,
      );
      print('Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        await _fetchOrders();
        _showError('Commande ajoutée avec succès', isError: false);
      } else {
        _showError('Error adding order: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error adding order: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editOrder(String id, Map<String, dynamic> orderData) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'productId': orderData['productId'],
        'clientId': orderData['clientId'],
        'deliveryDate': orderData['deliveryDate'],
        'paymentType': orderData['paymentType'],
        'status': orderData['status'],
      });
      print('Editing order with body: $body');
      final response = await http.put(
        Uri.parse('$apiUrl/api/orders/$id'),
        headers: headers,
        body: body,
      );
      print('Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        await _fetchOrders();
        _showError('Commande modifiée avec succès', isError: false);
      } else {
        _showError('Error editing order: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error editing order: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteOrder(
    String id,
    String productName,
    String clientName,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete order for "$productName" by "$clientName"?'),
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
        Uri.parse('$apiUrl/api/orders/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        await _fetchOrders();
        _showError('Commande supprimée avec succès', isError: false);
      } else {
        _showError('Error deleting order: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error deleting order: $e');
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

  Future<void> _showAddEditDialog({Map<String, dynamic>? order}) async {
    String? productId = order?['productId'];
    String? clientId = order?['clientId'];
    DateTime? deliveryDate = order != null
        ? DateTime.parse(order['deliveryDate'])
        : null;
    String? paymentType = order?['paymentType'];
    String? status = order?['status'] ?? 'Pending';

    final dateController = TextEditingController(
      text: deliveryDate != null
          ? DateFormat('yyyy-MM-dd').format(deliveryDate)
          : '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(order == null ? 'Add Order' : 'Edit Order'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Product'),
                    value: productId,
                    items: products
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p['_id'] as String,
                            child: Text(p['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => productId = value),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Client'),
                    value: clientId,
                    items: clients
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['_id'] as String,
                            child: Text(c['fullName'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => clientId = value),
                  ),
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Date',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: deliveryDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          deliveryDate = picked;
                          dateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        });
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Payment Type',
                    ),
                    value: paymentType,
                    items: ['Cash', 'Credit Card', 'Bank Transfer']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => paymentType = value),
                  ),
                  if (order != null)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Status'),
                      value: status,
                      items: ['Pending', 'Confirmed', 'Delivered']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => status = value),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (productId == null ||
                      clientId == null ||
                      deliveryDate == null ||
                      paymentType == null) {
                    _showError('All fields are required');
                    return;
                  }
                  Navigator.pop(context);
                  if (order == null) {
                    _addOrder({
                      'productId': productId,
                      'clientId': clientId,
                      'deliveryDate': deliveryDate?.toIso8601String() ?? '',
                      'paymentType': paymentType,
                    });
                  } else {
                    _editOrder(order['_id'], {
                      'productId': productId,
                      'clientId': clientId,
                      'deliveryDate': deliveryDate?.toIso8601String() ?? '',
                      'paymentType': paymentType,
                      'status': status,
                    });
                  }
                },
                child: const Text('Save', style: TextStyle(color: Colors.teal)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchProductsAndClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orders',
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
          : orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No orders available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
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
                      order['productName'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Client: ${order['clientName']}'),
                        Text(
                          'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(order['deliveryDate']))}',
                        ),
                        Text('Payment: ${order['paymentType']}'),
                        Text('Status: ${order['status']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () => _showAddEditDialog(order: order),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteOrder(
                            order['_id'],
                            order['productName'],
                            order['clientName'],
                          ),
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
