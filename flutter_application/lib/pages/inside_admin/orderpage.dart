import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models (keeping existing models unchanged)
class Product {
  final String id;
  final String name;
  final double price;
  final int quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      quantity: _parseInt(json['quantity']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class Client {
  final String id;
  final String fullName;
  final String? email;
  final String? number;
  final String fiscalNumber;

  Client({
    required this.id,
    required this.fullName,
    this.email,
    this.number,
    required this.fiscalNumber,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Unknown Client',
      email: json['email']?.toString(),
      number: json['number']?.toString(),
      fiscalNumber: json['fiscalNumber']?.toString() ?? '',
    );
  }
}

class OrderProduct {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {'productId': productId, 'quantity': quantity, 'price': price};
  }

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    try {
      final productIdData = json['productId'];
      String id;
      String name = 'Unknown Product';
      if (productIdData is Map<String, dynamic>) {
        id = productIdData['_id']?.toString() ?? '';
        name = productIdData['name']?.toString() ?? 'Unknown Product';
      } else {
        id = productIdData?.toString() ?? '';
      }
      return OrderProduct(
        productId: id,
        productName: name,
        quantity: Product._parseInt(json['quantity']),
        price: Product._parseDouble(json['price']),
      );
    } catch (e) {
      print('Error parsing OrderProduct: $e');
      return OrderProduct(
        productId: '',
        productName: 'Unknown Product',
        quantity: 0,
        price: 0.0,
      );
    }
  }
}

class Order {
  final String id;
  final List<OrderProduct> products;
  final Client client;
  final DateTime deliveryDate;
  final String paymentType;
  final String status;
  final double totalAmount;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.products,
    required this.client,
    required this.deliveryDate,
    required this.paymentType,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      return Order(
        id: json['_id']?.toString() ?? '',
        products: (json['products'] as List? ?? [])
            .map((p) => OrderProduct.fromJson(p))
            .toList(),
        client: Client.fromJson(
          json['clientId'] is String
              ? {'_id': json['clientId']}
              : json['clientId'] ?? {},
        ),
        deliveryDate: _parseDate(json['deliveryDate']),
        paymentType: json['paymentType']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Pending',
        totalAmount: Product._parseDouble(json['totalAmount']),
        createdAt: _parseDate(json['createdAt']),
      );
    } catch (e, stack) {
      print('Order parsing error: $e');
      print('Stack trace: $stack');
      print('Problematic JSON: $json');
      throw Exception('Failed to parse order: ${e.toString()}');
    }
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('Error parsing date: $dateValue');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Create a copy with updated status
  Order copyWith({
    String? id,
    List<OrderProduct>? products,
    Client? client,
    DateTime? deliveryDate,
    String? paymentType,
    String? status,
    double? totalAmount,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      products: products ?? this.products,
      client: client ?? this.client,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Enhanced API Service with status update functionality
class ApiService {
  static const String baseUrl = 'https://flutter-backend-xhrw.onrender.com';
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_token ?? ""}',
    'Content-Type': 'application/json',
  };

  static Future<http.Response> _handleRequest(
    Future<http.Response> request,
  ) async {
    try {
      final response = await request.timeout(const Duration(seconds: 30));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response;
    } catch (e) {
      print('Request error: $e');
      if (e is TimeoutException) {
        throw Exception('Request timed out. Please try again.');
      }
      throw Exception('Unable to connect. Check your internet.');
    }
  }

  // NEW: Update order status
  static Future<Order> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    print('Updating order ID: $orderId with status: $newStatus'); // Debug log
    final response = await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/status'),
        headers: _headers,
        body: jsonEncode({'status': newStatus}),
      ),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order'] ?? data);
      } catch (e) {
        print('Error parsing updated order: $e');
        throw Exception('Failed to parse updated order');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Order not found. It may have been deleted.');
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }
    throw Exception(_extractErrorMessage(response));
  }

  // Existing methods remain unchanged
  static Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/api/orders').replace(
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );
    final response = await _handleRequest(http.get(uri, headers: _headers));

    if (response.statusCode == 200) {
      try {
        final dynamic data = jsonDecode(response.body);

        List<Order> orders = [];
        int total = 0;

        if (data is List) {
          orders = data.map((json) => Order.fromJson(json)).toList();
          total = orders.length;
        } else if (data is Map<String, dynamic>) {
          orders = (data['orders'] as List? ?? [])
              .map((json) => Order.fromJson(json))
              .toList();
          total = data['total'] ?? orders.length;
        }

        return {'orders': orders, 'total': total};
      } catch (e) {
        print('Error parsing orders: $e');
        print('Response data: ${response.body}');
        throw Exception('Failed to parse orders: ${e.toString()}');
      }
    }
    throw Exception(_extractErrorMessage(response));
  }

  static Future<List<Client>> getClients(String? query) async {
    final uri = query == null || query.isEmpty
        ? Uri.parse('$baseUrl/api/clients')
        : Uri.parse(
            '$baseUrl/api/clients?search=${Uri.encodeComponent(query)}',
          );
    final response = await _handleRequest(http.get(uri, headers: _headers));

    if (response.statusCode == 200) {
      try {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((json) => Client.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Expected a list of clients');
      } catch (e) {
        print('Error parsing clients: $e');
        throw Exception('Failed to load clients');
      }
    }
    throw Exception(_extractErrorMessage(response));
  }

  static Future<List<Product>> getProducts(String? query) async {
    final uri = query == null || query.isEmpty
        ? Uri.parse('$baseUrl/api/products')
        : Uri.parse(
            '$baseUrl/api/products?search=${Uri.encodeComponent(query)}',
          );
    final response = await _handleRequest(http.get(uri, headers: _headers));

    if (response.statusCode == 200) {
      try {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Expected a list of products');
      } catch (e) {
        print('Error parsing products: $e');
        throw Exception('Failed to load products');
      }
    }
    throw Exception(_extractErrorMessage(response));
  }

  static Future<Order> createOrder({
    required List<OrderProduct> products,
    required String clientId,
    required DateTime deliveryDate,
    required String paymentType,
    String status = 'Pending',
  }) async {
    final requestBody = {
      'products': products.map((p) => p.toJson()).toList(),
      'clientId': clientId,
      'deliveryDate': deliveryDate.toIso8601String(),
      'paymentType': paymentType,
      'status': status,
    };

    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: _headers,
        body: jsonEncode(requestBody),
      ),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final orderData =
            data is Map<String, dynamic> && data.containsKey('order')
            ? data['order']
            : data;
        return Order.fromJson(orderData);
      } catch (e) {
        print('Error parsing created order: $e');
        throw Exception('Failed to parse created order');
      }
    }
    throw Exception(_extractErrorMessage(response));
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> && data.containsKey('message')
          ? data['message'].toString()
          : 'Server error (${response.statusCode})';
    } catch (e) {
      return 'Server error (${response.statusCode})';
    }
  }
}

// Token Retrieval Helper (unchanged)
Future<String> getAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null || token.isEmpty) {
    throw Exception('Please log in to continue');
  }
  return token;
}

// Enhanced Order Page with status update functionality
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _statusFilter = 'All';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchOrders(page: 1);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchOrders(page: _currentPage + 1);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({required int page}) async {
    print('Fetching orders, page $page');
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final token = await getAuthToken();
      print('Token: ${token.substring(0, 10)}...');
      ApiService.setToken(token);
      final result = await ApiService.getOrders(page: page, limit: _pageSize);
      final orders = result['orders'] as List<Order>;
      final total = result['total'] as int;

      if (mounted) {
        setState(() {
          if (page == 1) {
            _orders = orders;
          } else {
            _orders.addAll(orders);
          }
          _totalOrders = total;
          _applyFilters();
          _currentPage = page;
          _hasMore = _orders.length < _totalOrders;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error in _fetchOrders: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('timeout')
              ? 'Request timed out. Try again later.'
              : e.toString().contains('Network')
              ? 'Unable to connect. Check your internet.'
              : 'Failed to load orders. Please try again.';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Order> filtered = List.from(_orders);
    if (_statusFilter != 'All') {
      filtered = filtered
          .where(
            (order) =>
                order.status.toLowerCase() == _statusFilter.toLowerCase(),
          )
          .toList();
    }
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() => _filteredOrders = filtered);
  }

  Future<void> _refreshOrders() async {
    await _fetchOrders(page: 1);
  }

  // NEW: Update order status
  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      // Check if order exists in local list
      if (!_orders.any((o) => o.id == order.id)) {
        throw Exception('Order not found locally. It may have been deleted.');
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Verify order exists on backend
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/orders/${order.id}'),
        headers: ApiService._headers,
      );
      if (response.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (response.statusCode != 200) {
        throw Exception('Order not found. It may have been deleted.');
      }

      // Update status
      final updatedOrder = await ApiService.updateOrderStatus(
        order.id,
        newStatus,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        setState(() {
          final index = _orders.indexWhere((o) => o.id == order.id);
          if (index != -1) {
            _orders[index] = updatedOrder;
            _applyFilters();
          }
        });
        // Force refresh to sync with backend
        await _refreshOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (e.toString().contains('Order not found') ||
            e.toString().contains('404')) {
          errorMessage = 'Order not found. It may have been deleted.';
          await _refreshOrders(); // Refresh to remove deleted order
        } else if (e.toString().contains('Session expired') ||
            e.toString().contains('401')) {
          errorMessage = 'Session expired. Please log in again.';
          // Clear token and redirect to login
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          Navigator.pushReplacementNamed(context, '/login');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
        print('Status update error: $e');
      }
    }
  }

  // NEW: Show status update dialog
  void _showStatusUpdateDialog(Order order) {
    final availableStatuses = [
      'Pending',
      'Confirmed',
      'Delivered',
      'Cancelled',
    ];
    String selectedStatus = order.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${_getOrderDisplayId(order.id)}'),
            Text('Client: ${order.client.fullName}'),
            const SizedBox(height: 16),
            Text('Current Status: ${order.status}'),
            const SizedBox(height: 16),
            const Text('Select New Status:'),
            const SizedBox(height: 8),
            ...availableStatuses.map((status) {
              return RadioListTile<String>(
                title: Text(status),
                value: status,
                groupValue: selectedStatus,
                onChanged: (value) {
                  selectedStatus = value!;
                  // Update the dialog
                  Navigator.pop(context);
                  _showStatusUpdateDialog(order);
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedStatus != order.status
                ? () {
                    Navigator.pop(context);
                    _updateOrderStatus(order, selectedStatus);
                  }
                : null,
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateOrderForm(),
                  ),
                );
                if (result == true) {
                  _refreshOrders();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshOrders,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                        'All',
                        'Pending',
                        'Confirmed',
                        'Delivered',
                        'Cancelled',
                      ].map((filter) {
                        final isSelected = _statusFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _statusFilter = filter);
                                _applyFilters();
                              }
                            },
                            selectedColor: Colors.blue,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            if (_totalOrders > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      'Total Orders: $_totalOrders',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshOrders,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildErrorWidget()
                    : _filteredOrders.isEmpty
                    ? _buildEmptyWidget()
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        itemCount: _filteredOrders.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == _filteredOrders.length && _hasMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final order = _filteredOrders[index];
                          return AnimatedOpacity(
                            opacity: _isLoading ? 0.0 : 1.0,
                            duration: Duration(
                              milliseconds: 300 + (index * 100),
                            ),
                            child: _buildOrderCard(order),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error loading orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No orders found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first order by tapping the + button',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          'Order #${_getOrderDisplayId(order.id)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Client: ${order.client.fullName}'),
            Text(
              'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}',
            ),
            Text(
              'Delivery: ${DateFormat('MMM dd, yyyy').format(order.deliveryDate)}',
            ),
            Text('Items: ${order.products.length}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Enhanced status chip with tap functionality
                GestureDetector(
                  onTap: () => _showStatusUpdateDialog(order),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
                Text(
                  '\DT ${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => SingleChildScrollView(
            child: OrderDetails(
              order: order,
              onStatusUpdate: (newStatus) =>
                  _updateOrderStatus(order, newStatus),
            ),
          ),
        ),
      ),
    );
  }

  String _getOrderDisplayId(String id) {
    return id.length >= 6
        ? id.substring(id.length - 6).toUpperCase()
        : id.toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Enhanced Order Details with status update functionality
class OrderDetails extends StatelessWidget {
  final Order order;
  final Function(String)? onStatusUpdate;

  const OrderDetails({super.key, required this.order, this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #${_getOrderDisplayId(order.id)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  order.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Update Section
          if (onStatusUpdate != null) ...[
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          ['Pending', 'Confirmed', 'Delivered', 'Cancelled']
                              .where((status) => status != order.status)
                              .map((status) {
                                return ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onStatusUpdate!(status);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getStatusColor(status),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(status),
                                );
                              })
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildInfoSection('Client Information', [
            'Name: ${order.client.fullName}',
            'Email: ${order.client.email ?? 'Not provided'}',
            'Phone: ${order.client.number ?? 'Not provided'}',
            'Fiscal Number: ${order.client.fiscalNumber}',
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Order Details', [
            'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}',
            'Delivery Date: ${DateFormat('MMM dd, yyyy').format(order.deliveryDate)}',
            'Payment Type: ${order.paymentType}',
            'Total Amount: \${order.totalAmount.toStringAsFixed(2)}',
          ]),
          const SizedBox(height: 16),
          const Text(
            'Products:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...order.products.map(
            (p) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${p.quantity}x ${p.productName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('\DT ${(p.quantity * p.price).toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item),
          ),
        ),
      ],
    );
  }

  String _getOrderDisplayId(String id) {
    return id.length >= 6
        ? id.substring(id.length - 6).toUpperCase()
        : id.toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Create Order Form (unchanged from original)
class CreateOrderForm extends StatefulWidget {
  const CreateOrderForm({super.key});

  @override
  State<CreateOrderForm> createState() => _CreateOrderFormState();
}

class _CreateOrderFormState extends State<CreateOrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _clientSearchController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  Client? _selectedClient;
  String _paymentType = 'Cash';
  DateTime? _deliveryDate;
  final List<OrderProduct> _selectedProducts = [];
  List<Client> _clients = [];
  List<Product> _products = [];
  bool _isLoading = false;
  bool _isCreatingOrder = false;
  bool _isSearchingClients = false;
  bool _isSearchingProducts = false;
  bool _showClientDropdown = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _clientSearchController.dispose();
    _productSearchController.dispose();
    _deliveryDateController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await getAuthToken();
      ApiService.setToken(token);
      final clients = await ApiService.getClients(null);
      final products = await ApiService.getProducts(null);

      if (!mounted) return;
      setState(() {
        _clients = clients;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showError(
        'Failed to load data: ${e.toString().replaceAll('Exception: ', '')}',
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchClients(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isSearchingClients = true);
      try {
        final clients = await ApiService.getClients(query);
        if (!mounted) return;
        setState(() {
          _clients = clients;
          _showClientDropdown = query.isNotEmpty;
        });
      } catch (e) {
        if (!mounted) return;
        _showError('Error searching clients: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isSearchingClients = false);
        }
      }
    });
  }

  void _selectClient(Client client) {
    setState(() {
      _selectedClient = client;
      _clientSearchController.text =
          '${client.fullName} (${client.fiscalNumber})';
      _showClientDropdown = false;
    });
  }

  void _clearClientSelection() {
    setState(() {
      _selectedClient = null;
      _clientSearchController.clear();
      _showClientDropdown = false;
    });
    _loadData();
  }

  Future<void> _searchProducts(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isSearchingProducts = true);
      try {
        final products = await ApiService.getProducts(query);
        if (!mounted) return;
        setState(() => _products = products);
      } catch (e) {
        if (!mounted) return;
        _showError('Error searching products: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isSearchingProducts = false);
        }
      }
    });
  }

  Future<void> _selectDeliveryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _deliveryDate = date;
        _deliveryDateController.text = DateFormat('MMM dd, yyyy').format(date);
      });
    }
  }

  void _addProduct(Product product, int quantity) {
    setState(() {
      final existingIndex = _selectedProducts.indexWhere(
        (p) => p.productId == product.id,
      );
      if (existingIndex >= 0) {
        _selectedProducts[existingIndex] = OrderProduct(
          productId: product.id,
          productName: product.name,
          quantity: _selectedProducts[existingIndex].quantity + quantity,
          price: product.price,
        );
      } else {
        _selectedProducts.add(
          OrderProduct(
            productId: product.id,
            productName: product.name,
            quantity: quantity,
            price: product.price,
          ),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} × $quantity'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  double get _totalAmount {
    return _selectedProducts.fold(
      0.0,
      (sum, product) => sum + (product.quantity * product.price),
    );
  }

  int _getAvailableStock(Product product) {
    final selectedProduct = _selectedProducts.firstWhere(
      (p) => p.productId == product.id,
      orElse: () =>
          OrderProduct(productId: '', productName: '', quantity: 0, price: 0),
    );
    return product.quantity - selectedProduct.quantity;
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProducts.isEmpty) {
      _showError('Please add at least one product');
      return;
    }

    setState(() => _isCreatingOrder = true);
    try {
      await ApiService.createOrder(
        products: _selectedProducts,
        clientId: _selectedClient!.id,
        deliveryDate: _deliveryDate!,
        paymentType: _paymentType,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(
        e.toString().contains('Server error') ||
                e.toString().contains('Network')
            ? 'Unable to create order. Please try again.'
            : e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingOrder = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Client',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        TextFormField(
                          controller: _clientSearchController,
                          decoration: InputDecoration(
                            labelText: _selectedClient == null
                                ? 'Search and select client'
                                : 'Selected client',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSearchingClients)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                if (_selectedClient != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearClientSelection,
                                  ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          readOnly: _selectedClient != null,
                          onChanged: (value) {
                            if (_selectedClient == null) {
                              if (value.isEmpty) {
                                setState(() => _showClientDropdown = false);
                                _loadData();
                              } else {
                                _searchClients(value);
                              }
                            }
                          },
                          onTap: () {
                            if (_selectedClient == null) {
                              setState(() => _showClientDropdown = true);
                            }
                          },
                          validator: (value) => _selectedClient == null
                              ? 'Please select a client'
                              : null,
                        ),
                        if (_showClientDropdown && _clients.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _clients.length,
                              itemBuilder: (context, index) {
                                final client = _clients[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(client.fullName),
                                  subtitle: Text(
                                    'Fiscal: ${client.fiscalNumber}${client.email != null ? ' • ${client.email}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onTap: () => _selectClient(client),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Add Products',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _productSearchController,
                      decoration: InputDecoration(
                        labelText: 'Search products',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _isSearchingProducts
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) =>
                          value.isEmpty ? _loadData() : _searchProducts(value),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final available = _getAvailableStock(product);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(product.name),
                              subtitle: Text(
                                'Stock: $available | Price: \DT ${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: available > 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: available > 0
                                    ? () => _showAddProductDialog(product)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedProducts.isNotEmpty) ...[
                      const Text(
                        'Selected Products',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ..._selectedProducts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final product = entry.value;
                        return Card(
                          child: ListTile(
                            title: Text(product.productName),
                            subtitle: Text(
                              '${product.quantity} × \${product.price.toStringAsFixed(2)} = \${(product.quantity * product.price).toStringAsFixed(2)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeProduct(index),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\DT ${_totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    TextFormField(
                      controller: _deliveryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Date',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: _selectDeliveryDate,
                      validator: (value) =>
                          _deliveryDate == null ? 'Please select a date' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _paymentType,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Cash', 'Credit Card', 'Bank Transfer'].map((
                        method,
                      ) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _paymentType = value!),
                      validator: (value) =>
                          value == null ? 'Please select a method' : null,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isCreatingOrder ? null : _createOrder,
                        child: _isCreatingOrder
                            ? const CircularProgressIndicator()
                            : const Text('Create Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showAddProductDialog(Product product) {
    int quantity = 1;
    final available = _getAvailableStock(product);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available: $available'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                  ),
                  Text('$quantity', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: quantity < available
                        ? () => setState(() => quantity++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addProduct(product, quantity);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
