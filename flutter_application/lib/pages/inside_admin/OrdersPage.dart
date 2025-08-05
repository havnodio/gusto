import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Models
class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int quantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
    );
  }
}

class Client {
  final String id;
  final String fullName;
  final String email;
  final String phone;

  Client({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class OrderProduct {
  final Product product;
  final int quantity;
  final double price;

  OrderProduct({
    required this.product,
    required this.quantity,
    required this.price,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      product: Product.fromJson(json['productId'] ?? {}),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'productId': product.id, 'quantity': quantity, 'price': price};
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
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.products,
    required this.client,
    required this.deliveryDate,
    required this.paymentType,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      products: (json['products'] as List? ?? [])
          .map((p) => OrderProduct.fromJson(p))
          .toList(),
      client: Client.fromJson(json['clientId'] ?? {}),
      deliveryDate: DateTime.parse(
        json['deliveryDate'] ?? DateTime.now().toIso8601String(),
      ),
      paymentType: json['paymentType'] ?? '',
      status: json['status'] ?? 'Pending',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// API Service
class ApiService {
  static const String baseUrl = 'https://your-api-base-url'; // Configure this
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
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Order>> getOrders() async {
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/api/orders'), headers: _headers),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to load orders',
      );
    }
  }

  static Future<List<Client>> getClients() async {
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/api/clients'), headers: _headers),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Client.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load clients');
    }
  }

  static Future<List<Product>> getProducts() async {
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/api/products'), headers: _headers),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<Order> createOrder({
    required List<OrderProduct> products,
    required String clientId,
    required DateTime deliveryDate,
    required String paymentType,
    String status = 'Pending',
  }) async {
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: _headers,
        body: jsonEncode({
          'products': products.map((p) => p.toJson()).toList(),
          'clientId': clientId,
          'deliveryDate': deliveryDate.toIso8601String(),
          'paymentType': paymentType,
          'status': status,
        }),
      ),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data['order']);
    } else {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to create order',
      );
    }
  }

  static Future<Order> updateOrder({
    required String orderId,
    required List<OrderProduct> products,
    required String clientId,
    required DateTime deliveryDate,
    required String paymentType,
    required String status,
  }) async {
    final response = await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: _headers,
        body: jsonEncode({
          'products': products.map((p) => p.toJson()).toList(),
          'clientId': clientId,
          'deliveryDate': deliveryDate.toIso8601String(),
          'paymentType': paymentType,
          'status': status,
        }),
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data['order']);
    } else {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to update order',
      );
    }
  }

  static Future<void> deleteOrder(String orderId) async {
    final response = await _handleRequest(
      http.delete(Uri.parse('$baseUrl/api/orders/$orderId'), headers: _headers),
    );

    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to delete order',
      );
    }
  }
}

// Enhanced Order Page
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with TickerProviderStateMixin {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  List<Client> _clients = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'All';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_fetchOrders(), _fetchClients(), _fetchProducts()]);
      _animationController.forward();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final orders = await ApiService.getOrders();
      setState(() {
        _orders = orders;
        _applyFilters();
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _fetchClients() async {
    try {
      _clients = await ApiService.getClients();
    } catch (e) {
      debugPrint('Failed to load clients: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      _products = await ApiService.getProducts();
    } catch (e) {
      debugPrint('Failed to load products: $e');
    }
  }

  void _applyFilters() {
    List<Order> filtered = _orders;

    // Apply status filter
    if (_statusFilter != 'All') {
      filtered = filtered
          .where((order) => order.status == _statusFilter)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.client.fullName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.products.any(
              (p) => p.product.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            );
      }).toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() => _filteredOrders = filtered);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() => _statusFilter = filter);
    _applyFilters();
  }

  Future<void> _refreshOrders() async {
    HapticFeedback.lightImpact();
    await _fetchOrders();
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);

      await ApiService.updateOrder(
        orderId: orderId,
        products: order.products,
        clientId: order.client.id,
        deliveryDate: order.deliveryDate,
        paymentType: order.paymentType,
        status: newStatus,
      );

      await _fetchOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      await ApiService.deleteOrder(orderId);
      await _fetchOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete order: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildOrderCard(Order order) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Order #${order.id.substring(order.id.length - 6)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person, order.client.fullName),
                _buildInfoRow(
                  Icons.calendar_today,
                  DateFormat('MMM dd, yyyy').format(order.deliveryDate),
                ),
                _buildInfoRow(
                  Icons.attach_money,
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                ),
                _buildInfoRow(Icons.payment, order.paymentType),
                _buildInfoRow(
                  Icons.shopping_cart,
                  '${order.products.length} item${order.products.length != 1 ? 's' : ''}',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showStatusUpdateDialog(order),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("Update"),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _showDeleteConfirmation(order.id),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text("Delete"),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order #${order.id.substring(order.id.length - 6)}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailSection("Customer Information", [
                _buildDetailRow("Name", order.client.fullName),
                _buildDetailRow("Email", order.client.email),
                _buildDetailRow("Phone", order.client.phone),
              ]),
              const SizedBox(height: 16),
              _buildDetailSection("Order Information", [
                _buildDetailRow(
                  "Delivery Date",
                  DateFormat('EEEE, MMM dd, yyyy').format(order.deliveryDate),
                ),
                _buildDetailRow("Payment Type", order.paymentType),
                _buildDetailRow(
                  "Total Amount",
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  "Created",
                  DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt),
                ),
              ]),
              const SizedBox(height: 16),
              _buildDetailSection(
                "Products",
                order.products
                    .map(
                      (p) =>
                          _buildProductRow(p.product.name, p.quantity, p.price),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showStatusUpdateDialog(order);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Update Order Status"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(String name, int quantity, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text("Qty: $quantity"),
          const SizedBox(width: 16),
          Text("\$${price.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Update Order #${order.id.substring(order.id.length - 6)}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Pending', 'Confirmed', 'Delivered'].map((status) {
            return ListTile(
              leading: Icon(
                order.status == status
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: _getStatusColor(status),
              ),
              title: Text(status),
              onTap: () {
                if (status != order.status) {
                  _updateOrderStatus(order.id, status);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Order"),
        content: const Text(
          "Are you sure you want to delete this order? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteOrder(orderId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateOrderForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOrderPage(
          clients: _clients,
          products: _products,
          onOrderCreated: _fetchOrders,
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
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Orders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateOrderForm,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search orders, customers, products...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Pending', 'Confirmed', 'Delivered'].map((
                      filter,
                    ) {
                      final isSelected = _statusFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) => _onFilterChanged(filter),
                          backgroundColor: Colors.grey[100],
                          selectedColor: Colors.blue.withOpacity(0.2),
                          checkmarkColor: Colors.blue,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshOrders,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initializeData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _statusFilter != 'All'
                                ? 'No orders match your filters'
                                : 'No orders found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _statusFilter != 'All') ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                _onFilterChanged('All');
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) =>
                          _buildOrderCard(_filteredOrders[index]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOrderForm,
        icon: const Icon(Icons.add),
        label: const Text("New Order"),
      ),
    );
  }
}

// Placeholder for Create Order Page
class CreateOrderPage extends StatelessWidget {
  final List<Client> clients;
  final List<Product> products;
  final VoidCallback onOrderCreated;

  const CreateOrderPage({
    super.key,
    required this.clients,
    required this.products,
    required this.onOrderCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Order"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const CreateOrderForm(),
    );
  }
}

// Create Order Form Widget
class CreateOrderForm extends StatefulWidget {
  const CreateOrderForm({super.key});

  @override
  State<CreateOrderForm> createState() => _CreateOrderFormState();
}

class _CreateOrderFormState extends State<CreateOrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _deliveryDateController = TextEditingController();

  Client? _selectedClient;
  String _selectedPaymentType = 'Cash';
  DateTime? _selectedDeliveryDate;
  List<OrderProduct> _selectedProducts = [];
  bool _isLoading = false;

  List<Client> _clients = [];
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _deliveryDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true); // Show loading indicator
    try {
      // Ensure token is set (replace with your auth logic)
      ApiService.setToken('your-token-here'); // Set token from auth system
      final clients = await ApiService.getClients();
      final products = await ApiService.getProducts();
      setState(() {
        _clients = clients;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  void _addProduct(Product product, int quantity) {
    final existingIndex = _selectedProducts.indexWhere(
      (p) => p.product.id == product.id,
    );

    setState(() {
      if (existingIndex >= 0) {
        _selectedProducts[existingIndex] = OrderProduct(
          product: product,
          quantity: _selectedProducts[existingIndex].quantity + quantity,
          price: product.price,
        );
      } else {
        _selectedProducts.add(
          OrderProduct(
            product: product,
            quantity: quantity,
            price: product.price,
          ),
        );
      }
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  void _updateProductQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeProduct(index);
    } else {
      setState(() {
        _selectedProducts[index] = OrderProduct(
          product: _selectedProducts[index].product,
          quantity: newQuantity,
          price: _selectedProducts[index].price,
        );
      });
    }
  }

  double get _totalAmount {
    return _selectedProducts.fold(
      0.0,
      (sum, product) => sum + (product.price * product.quantity),
    );
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
        _selectedDeliveryDate = date;
        _deliveryDateController.text = DateFormat('MMM dd, yyyy').format(date);
      });
    }
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.createOrder(
        products: _selectedProducts,
        clientId: _selectedClient!.id,
        deliveryDate: _selectedDeliveryDate!,
        paymentType: _selectedPaymentType,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create order: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_clients.isEmpty && _products.isEmpty)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No clients or products found'),
                  TextButton(onPressed: _loadData, child: const Text('Retry')),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === Client Dropdown ===
                        const Text(
                          'Select Client',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Client>(
                          value: _selectedClient,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'Choose a client',
                          ),
                          validator: (value) =>
                              value == null ? 'Please select a client' : null,
                          items: _clients.map((client) {
                            return DropdownMenuItem(
                              value: client,
                              child: Text(
                                '${client.fullName} (${client.email})',
                              ),
                            );
                          }).toList(),
                          onChanged: (client) =>
                              setState(() => _selectedClient = client),
                        ),
                        const SizedBox(height: 20),

                        // === Delivery Date ===
                        const Text(
                          'Delivery Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _deliveryDateController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'Select delivery date',
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          validator: (value) => _selectedDeliveryDate == null
                              ? 'Please select a delivery date'
                              : null,
                          onTap: _selectDeliveryDate,
                        ),
                        const SizedBox(height: 20),

                        // === Payment Type ===
                        const Text(
                          'Payment Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedPaymentType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ['Cash', 'Credit Card', 'Bank Transfer'].map((
                            type,
                          ) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (type) =>
                              setState(() => _selectedPaymentType = type!),
                        ),
                        const SizedBox(height: 20),

                        // === Product Section ===
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Products',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showProductSelector,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Product'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_selectedProducts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No products added yet',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(_selectedProducts.length, (index) {
                            final orderProduct = _selectedProducts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  child: Text(
                                    orderProduct.product.name
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(orderProduct.product.name),
                                subtitle: Text(
                                  '${orderProduct.product.category} • \$${orderProduct.price.toStringAsFixed(2)} each',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _updateProductQuantity(
                                        index,
                                        orderProduct.quantity - 1,
                                      ),
                                      icon: const Icon(Icons.remove),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        orderProduct.quantity.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _updateProductQuantity(
                                        index,
                                        orderProduct.quantity + 1,
                                      ),
                                      icon: const Icon(Icons.add),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeProduct(index),
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                        if (_selectedProducts.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${_totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // === Create Order Button ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Create Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showProductSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: Text(
                          product.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.category} • \${product.price.toStringAsFixed(2)}\nStock: ${product.quantity}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: product.quantity > 0
                            ? () {
                                _showQuantityDialog(product);
                              }
                            : null,
                        child: const Text('Add'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(Product product) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Price: \${product.price.toStringAsFixed(2)}'),
              Text('Available: ${product.quantity}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: quantity < product.quantity
                        ? () => setState(() => quantity++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: \${(product.price * quantity).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                Navigator.pop(context); // Close quantity dialog
                Navigator.pop(context); // Close product selector
              },
              child: const Text('Add to Order'),
            ),
          ],
        ),
      ),
    );
  }
}
