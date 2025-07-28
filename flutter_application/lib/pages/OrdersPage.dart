import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
  final String apiUrl = 'https://flutter-backend-xhrw.onrender.com/api/orders';
  final String productsApiUrl =
      'https://flutter-backend-xhrw.onrender.com/api/products';
  final String clientsApiUrl =
      'https://flutter-backend-xhrw.onrender.com/api/clients';

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
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          orders = data
              .map(
                (item) => {
                  '_id': item['_id'],
                  'productName': item['productId']['name'],
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
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final productsResponse = await http.get(
        Uri.parse(productsApiUrl),
        headers: headers,
      );
      if (productsResponse.statusCode == 200) {
        final productsData = jsonDecode(productsResponse.body) as List;
        setState(() {
          products = productsData
              .map(
                (item) => {
                  '_id': item['_id'],
                  'name': item['name'],
                  'quantity': item['quantity'],
                },
              )
              .toList();
        });
      }
      final clientsResponse = await http.get(
        Uri.parse(clientsApiUrl),
        headers: headers,
      );
      if (clientsResponse.statusCode == 200) {
        final clientsData = jsonDecode(clientsResponse.body) as List;
        setState(() {
          clients = clientsData
              .map((item) => {'_id': item['_id'], 'fullName': item['fullName']})
              .toList();
        });
      }
    } catch (e) {
      _showError('Error fetching products or clients: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addOrder(
    String productId,
    String clientId,
    String deliveryDate,
    String paymentType,
  ) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = {
        'productId': productId,
        'clientId': clientId,
        'deliveryDate': deliveryDate,
        'paymentType': paymentType,
      };
      print('Adding order with body: $body');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );
      print('Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        await _fetchOrders();
        _showError('Commande ajoutée avec succès', isError: false);
      } else {
        _showError(
          'Error adding order: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _showError('Error adding order: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editOrder(
    String id,
    String productId,
    String clientId,
    String deliveryDate,
    String paymentType,
    String status,
  ) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = {
        'productId': productId,
        'clientId': clientId,
        'deliveryDate': deliveryDate,
        'paymentType': paymentType,
        'status': status,
      };
      print('Editing order with body: $body');
      final response = await http.put(
        Uri.parse('$apiUrl/$id'),
        headers: headers,
        body: jsonEncode(body),
      );
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
        Uri.parse('$apiUrl/$id'),
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

  void _showAddOrderDialog() {
    String? selectedProductId;
    String? selectedClientId;
    DateTime? selectedDate;
    String? selectedPaymentType;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Add New Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Product *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: products
                      .where((p) => p['quantity'] > 0)
                      .map<DropdownMenuItem<String>>(
                        (product) => DropdownMenuItem<String>(
                          value: product['_id'] as String,
                          child: Text(
                            '${product['name']} (Stock: ${product['quantity']})',
                          ),
                        ),
                      )
                      .toList(),
                  value: selectedProductId,
                  onChanged: (value) =>
                      setState(() => selectedProductId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Client *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: clients
                      .map<DropdownMenuItem<String>>(
                        (client) => DropdownMenuItem<String>(
                          value: client['_id'] as String,
                          child: Text(client['fullName']),
                        ),
                      )
                      .toList(),
                  value: selectedClientId,
                  onChanged: (value) =>
                      setState(() => selectedClientId = value),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() => selectedDate = pickedDate);
                    }
                  },
                  child: Text(
                    selectedDate == null
                        ? 'Select Delivery Date *'
                        : 'Delivery: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Payment Type *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['Cash', 'Credit Card', 'Bank Transfer']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  value: selectedPaymentType,
                  onChanged: (value) =>
                      setState(() => selectedPaymentType = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedProductId == null ||
                  selectedClientId == null ||
                  selectedDate == null ||
                  selectedPaymentType == null) {
                _showError('All fields are required');
                return;
              }
              await _addOrder(
                selectedProductId!,
                selectedClientId!,
                selectedDate!.toIso8601String(),
                selectedPaymentType!,
              );
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

  void _showEditOrderDialog(int index) {
    final order = orders[index];
    String? selectedProductId = order['productId']['_id'];
    String? selectedClientId = order['clientId']['_id'];
    DateTime? selectedDate = DateTime.parse(order['deliveryDate']);
    String? selectedPaymentType = order['paymentType'];
    String? selectedStatus = order['status'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Edit Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Product *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: products
                      .where(
                        (p) =>
                            p['quantity'] > 0 || p['_id'] == selectedProductId,
                      )
                      .map<DropdownMenuItem<String>>(
                        (product) => DropdownMenuItem<String>(
                          value: product['_id'] as String,
                          child: Text(
                            '${product['name']} (Stock: ${product['quantity']})',
                          ),
                        ),
                      )
                      .toList(),
                  value: selectedProductId,
                  onChanged: (value) =>
                      setState(() => selectedProductId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Client *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: clients
                      .map<DropdownMenuItem<String>>(
                        (client) => DropdownMenuItem<String>(
                          value: client['_id'] as String,
                          child: Text(client['fullName']),
                        ),
                      )
                      .toList(),
                  value: selectedClientId,
                  onChanged: (value) =>
                      setState(() => selectedClientId = value),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() => selectedDate = pickedDate);
                    }
                  },
                  child: Text(
                    selectedDate == null
                        ? 'Select Delivery Date *'
                        : 'Delivery: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Payment Type *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['Cash', 'Credit Card', 'Bank Transfer']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  value: selectedPaymentType,
                  onChanged: (value) =>
                      setState(() => selectedPaymentType = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['Pending', 'Confirmed', 'Delivered']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  value: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedProductId == null ||
                  selectedClientId == null ||
                  selectedDate == null ||
                  selectedPaymentType == null ||
                  selectedStatus == null) {
                _showError('All fields are required');
                return;
              }
              await _editOrder(
                order['_id'],
                selectedProductId!,
                selectedClientId!,
                selectedDate!.toIso8601String(),
                selectedPaymentType!,
                selectedStatus!,
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
    _fetchProductsAndClients();
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orders Management',
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
                      'Order for ${order['productName']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Client: ${order['clientName']}'),
                        Text(
                          'Delivery: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(order['deliveryDate']))}',
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
                          onPressed: () => _showEditOrderDialog(index),
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
        onPressed: _showAddOrderDialog,
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
