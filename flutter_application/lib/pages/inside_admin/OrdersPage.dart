import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> orders = [];
  List<dynamic> products = [];
  List<dynamic> clients = [];
  bool loading = false;
  String? errorMessage;

  final String baseUrl = 'https://flutter-backend-xhrw.onrender.com/api/orders';

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchAllData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      await fetchProducts();
      await fetchClients();
      await fetchOrders();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> fetchOrders() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && mounted) {
      setState(() {
        orders = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<void> fetchProducts() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('https://flutter-backend-xhrw.onrender.com/api/products'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && mounted) {
      setState(() {
        products = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<void> fetchClients() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('https://flutter-backend-xhrw.onrender.com/api/clients'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && mounted) {
      setState(() {
        clients = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load clients');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'confirmed':
        return Colors.blue.shade700;
      case 'delivered':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> addOrUpdateOrder({Map<String, dynamic>? order}) async {
    final isNew = order == null;
    final existingOrder = order ?? {};

    final deliveryDateController = TextEditingController(
      text: isNew
          ? ''
          : DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.parse(existingOrder['deliveryDate'])),
    );

    String selectedProductId = isNew
        ? (products.isNotEmpty ? products.first['_id'] : '')
        : (existingOrder['productId'] is Map
              ? existingOrder['productId']['_id']
              : existingOrder['productId'] ?? '');

    String selectedClientId = isNew
        ? (clients.isNotEmpty ? clients.first['_id'] : '')
        : (existingOrder['clientId'] is Map
              ? existingOrder['clientId']['_id']
              : existingOrder['clientId'] ?? '');

    String selectedPaymentType = isNew
        ? 'Cash'
        : (existingOrder['paymentType'] ?? 'Cash');
    String selectedStatus = isNew
        ? 'Pending'
        : (existingOrder['status'] ?? 'Pending');

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isNew ? 'Add Order' : 'Edit Order'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedProductId.isNotEmpty
                          ? selectedProductId
                          : null,
                      items: products
                          .map<DropdownMenuItem<String>>(
                            (p) => DropdownMenuItem(
                              value: p['_id'],
                              child: Text(p['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value != null) selectedProductId = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Product'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedClientId.isNotEmpty
                          ? selectedClientId
                          : null,
                      items: clients
                          .map<DropdownMenuItem<String>>(
                            (c) => DropdownMenuItem(
                              value: c['_id'],
                              child: Text(c['fullName']),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value != null) selectedClientId = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Client'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deliveryDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Delivery Date',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate:
                                  deliveryDateController.text.isNotEmpty
                                  ? DateTime.parse(deliveryDateController.text)
                                  : DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                deliveryDateController.text = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(pickedDate);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPaymentType,
                      items: ['Cash', 'Credit Card', 'Bank Transfer']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value != null) selectedPaymentType = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Payment Type',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: ['Pending', 'Confirmed', 'Delivered']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value != null) selectedStatus = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final token = await getToken();
                    final url = isNew ? baseUrl : '$baseUrl/${order!['_id']}';
                    final method = isNew ? http.post : http.put;

                    final response = await method(
                      Uri.parse(url),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: json.encode({
                        'productId': selectedProductId,
                        'clientId': selectedClientId,
                        'deliveryDate': deliveryDateController.text,
                        'paymentType': selectedPaymentType,
                        'status': selectedStatus,
                      }),
                    );

                    if (!mounted) return;

                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      Navigator.pop(context);
                      fetchOrders();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isNew
                                ? 'Order added successfully'
                                : 'Order updated successfully',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to save order: ${response.body}',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(isNew ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteOrder(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && mounted) {
      fetchOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete order')));
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Extract product and client info safely
    final product = order['productId'] is Map ? order['productId'] : {};
    final client = order['clientId'] is Map ? order['clientId'] : {};

    final productName = product['name'] ?? 'Unknown product';
    final clientName = client['fullName'] ?? 'Unknown client';

    String formattedDate = 'Invalid date';
    try {
      formattedDate = DateFormat(
        'MMM dd, yyyy',
      ).format(DateTime.parse(order['deliveryDate']));
    } catch (_) {}

    final paymentType = order['paymentType'] ?? '';
    final status = order['status'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with product & client
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Client: $clientName',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Delivery: $formattedDate',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Payment: $paymentType',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const Divider(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Ink(
                  decoration: const ShapeDecoration(
                    color: Colors.blueAccent,
                    shape: CircleBorder(),
                    shadows: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => addOrUpdateOrder(order: order),
                    tooltip: 'Edit Order',
                  ),
                ),
                const SizedBox(width: 12),
                Ink(
                  decoration: const ShapeDecoration(
                    color: Colors.redAccent,
                    shape: CircleBorder(),
                    shadows: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => deleteOrder(order['_id']),
                    tooltip: 'Delete Order',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Orders Management',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'Refresh',
            onPressed: loading ? null : fetchAllData,
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading orders...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: fetchAllData,
                      child: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              )
            : orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'No orders found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the Add Order button to create your first order',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with total and Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Orders: ${orders.length}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => addOrUpdateOrder(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(orders[index]);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
